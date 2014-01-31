#encoding: utf-8

module Hifi
  module Spotify
    include Controllable
    LONG_EXPIRES = 60 * 20
    NET_STALENESS = 60
    STATE_KEY = "Spotify"

    PARAMS = ["NLS", "NAT", "NAL", "NTM", "NJA", "NTI", "NST", "NKY"]

    def select_spotify
      info =  YAML.load(open("account_info.yml", 'r').read)["spotify"]
      un = info["username"]
      pw = info["password"]
      un = un + ("\00" * (128 - un.size))
      pw = pw + ("\00" * (128 - pw.size))
      cmd("NSV", "0A1#{un}#{pw}" ) #connects to Spotify
    end


    def at_spotify_top?
      get_net_state(:list)[0...3].map(&:raw_text) == ["Search", "What's New", "Starred"]
    end

    def at_net_top?
      get_net_state(:list)[0...3].map(&:raw_text) == ["TuneIn", "Pandora Internet Radio", "Rhapsody"]
    end

    def choose_by_name(selection)
      return if current_list.nil?
      i = current_list.find_index{|entry| entry.nil? ? false : entry.raw_text.match(Regexp.new(selection.to_s, Regexp::IGNORECASE)) }
      return if i.nil?
      choose i
      self
    end
    def choose(index)
      raise ArgumentError, "needs to be 0-9, you gave #{index}" unless index.between?(0, 9)
      play if current_list[index] && current_list[index].type == "Song"
      cmd("NLS", "L#{index}")
      self
    end

    def spotify_top!
      cmd("NTC", "TOP") unless at_net_top? || at_spotify_top?
    end

    def search(query)
      spotify_top!
      choose(6) if at_net_top? #select Spotify
      choose(0) #select Search
      sleep 0.5
      if @ready_for_keyboard_input == true
        cmd("NKY", query)
        @ready_for_keyboard_input = false
      else
        # search(query)
      end
    end

    def current_list
      list = get_net_state(:list)
      list.compact!
      puts "\t#{list.map{|l| l.to_s + "\n"}}"
      list
    end

    def parse_nls(param)
      list = get_net_state(:list, [])
      cursor = get_net_state(:cursor, {:info => nil, :location => 0})
      # "tlpnnnnnnnnnn"
      # "NET/USB List Info
      # t ->Information Type (A : ASCII letter, C : Cursor Info, U : Unicode letter)
      # when t = A,
      #   l ->Line Info (0-9 : 1st to 10th Line)
      #   nnnnnnnnn:Listed data (variable-length, 64 ASCII letters max)
      #     when AVR is not displayed NET/USB List(Keyboard,Menu,Popup…), ""nnnnnnnnn"" is ""See TV"".
      #   p ->Property
      #          - : no
      #          0 : Playing, A : Artist, B : Album, F : Folder, M : Music, P : Playlist, S : Search
      #          a : Account, b : Playlist-C, c : Starred, d : Unstarred, e : What's New
      # when t = C,
      #   l ->Cursor Position (0-9 : 1st to 10th Line, - : No Cursor)
      #   p ->Update Type (P : Page Infomation Update ( Page Clear or Disable List Info) , C : Cursor Position Update)
      # when t = U, (for Network Control Only)
      #   l ->Line Info (0-9 : 1st to 10th Line)
      #   nnnnnnnnn:Listed data (variable-length, 64 Unicode letters [UTF-8 encoded] max)
      #     when AVR is not displayed NET/USB List(Keyboard,Menu,Popup…), ""nnnnnnnnn"" is ""See TV"".
      #   p ->Property
      #          - : no
      #          0 : Playing, A : Artist, B : Album, F : Folder, M : Music, P : Playlist, S : Search
      #          a : Account, b : Playlist-C, c : Starred, d : Unstarred, e : What's New"
      info_types = { "0" => "Playing", "A" => "Artist", "B" => "Album", 
        "F" => "Folder", "M" => "Music", "P" => "Playlist", "S" => "Search",
        "a" => "Account", "b" => "Playlist", "C" => "Starred", 
        "c" => "Starred", "d" => "Unstarred", "e" => "What\'s New",
        "T" => "Track" #added by J.B.M.
      }
      t, l, p, *n = param.chars

      if t == "C"
        if l == "-" && p == "P"
          list = [nil] * 10
          # cursor = {}
          puts "list cleared"
        else
          cursor[:info] = info_types[p]
          cursor[:location] = l
          puts "Cursor: #{cursor.inspect}"
        end
        list 
      elsif t == "U" || t == "A"
        raw_text =  n.join('')
        if t == "U"
          raw_text = raw_text.force_encoding("utf-8")
        end

        item = ListItem.new(l, p, raw_text)
        list ||= [nil] * 10
        list[l.to_i] = item
        puts "\t#{item}"
      end
      list.compact!

      set_net_state(:list, list)
      set_net_state(:cursor, cursor)
    end

    def self.get_params
      PARAMS
    end

    def set_net_state(key, val, custom_expires=NET_STALENESS)
      @net_state = get_state(STATE_KEY, {})
      @net_state[key] ||= {}
      @net_state[key][:result] = val
      @net_state[key][:expires] = Time.now - (custom_expires - NET_STALENESS)
      set_state(STATE_KEY, @net_state, LONG_EXPIRES) 
      val
    end
    def get_net_state(k, default=nil)
      return default unless @net_state && @net_state.include?(k) && @net_state[k].include?(:result)
      @net_state[k][:result]
    end
    def get_net_state_expires(k)
      @net_state[k][:expires]
    end
    def is_net_expired?(k)
      @net_state[k].nil? || (Time.now - @net_state[k][:expires]) > NET_STALENESS
    end


    def net_status
      #TODO: status as a hash for JSON
      get_title if title.nil?
      get_artist if artist.nil?
      get_album if album.nil?
      get_time if elapsed_time.nil?
      return if title.nil? || artist.nil? || album.nil? || elapsed_time.nil?
      diff = elapsed_time_secs - @last_putsed unless @last_putsed.nil?
      return if !diff.nil? && (diff < 30 && diff > 0) #TODO: better change detection
      status = (playing? ? '' : (paused? ? "Paused" : "Stopped" ) + " ")
      puts "#{status}#{title} by #{artist}, from #{album}; #{elapsed_time}/#{song_length}"
      @last_putsed = elapsed_time_secs
    end

    def self.parse_param(param, command, hifi)
      case command
      when "NLS"
        hifi.parse_nls(param)
      when "NST"
        hifi.parse_nst(param)
      when "NAT"
        hifi.parse_nat(param)
      when "NAL"
        hifi.parse_nal(param)
      when "NTI"
        hifi.parse_nti(param)
      when "NTM"
        hifi.parse_ntm(param)
      when "NKY"
        hifi.parse_nky(param)
      when "NJA"
        # ignore jacket art
      else
        STDERR.puts "Spotify parser doesn't know what to do with a #{command} command"
      end
    end

    def parse_nky(param)
      @ready_for_keyboard_input = true
    end

    def parse_nat(param)
      set_net_state(:artist, param)
      net_status
    end
    def parse_nal(param)
      set_net_state(:album, param)
      net_status
    end
    def parse_ntm(param)
      #00:01/04:12
      net_status
      curr, len = param.split("/")
      set_net_state(:elapsed_time, curr)
      set_net_state(:song_length, len)
    end
    def parse_nti(param)
      set_net_state(:title, param)
      net_status
    end
    #ugh these need to be method_missing?'ed
    def artist
      get_net_state(:artist)
    end
    def album
      get_net_state(:album)
    end
    def elapsed_time
      get_net_state(:elapsed_time)
    end
    def elapsed_time_secs
      min, secs = elapsed_time.split(":").map(&:to_i)
      min * 60 + secs
    end
    def song_length
      get_net_state(:song_length)
    end
    def song_length_secs
      min, secs = song_length.split(":").map(&:to_i)
      min * 60 + secs
    end
    def title
      get_net_state(:title)
    end

    #TODO: move this to controllable
    def playing?
      get_net_state(:playing) == :playing
    end
    def paused?
      get_net_state(:playing) == :paused
    end
    def stopped?
      get_net_state(:playing) == :stopped
    end
    def repeating?
      get_net_state(:repeat) != :off
    end
    def repeating?
      get_net_state(:repeat)
    end
    def shuffling?
      get_net_state(:shuffle) != :off
    end
    def shuffling
      get_net_state(:shuffle)
    end


    def get_title
      cmd("NTI", "QSTN")
    end
    def get_artist
      cmd("NAT", "QSTN")
    end
    def get_album
      cmd("NAL", "QSTN")
    end
    def get_time
      cmd("NTM", "QSTN")
    end
    def get_play_status
      cmd("NST", "QSTN")
    end

    def parse_nst(param)
  #         p -> Play Status: "S": STOP, "P": Play, "p": Pause, "F": FF, "R": FR
  #         r -> Repeat Status: "-": Off, "R": All, "F": Folder, "1": Repeat 1,
  #         s -> Shuffle Status: "-": Off, "S": All , "A": Album, "F": Folder'
      p, r, s = param.chars
      play_statuses = { "S" => :stopped, "P" => :playing, "p" => :paused, 
        "F" => :fast_forwarding, "R" => :rewinding }
      repeat_statuses = {"-" =>:off, "R" =>:all, "F" =>:folder, "1" =>:repeat_1}
      shuffle_statuses = {"-" => :off, "S" => :all , "A" => :album, "F" => :folder}
      set_net_state(:playing, play_statuses[p])
      set_net_state(:repeat, play_statuses[p])
      set_net_state(:shuffle, play_statuses[p])
    end


    # def read_nls_list(resps) # (this used to send an empty req. dunno if that's useful.)
    #   parsed_resps = parse_responses(resps)
    #   parsed_resps.select!{|resp| resp.command == "NLS"}
    #   choices = parsed_resps.map(&:parameter).map{|p| parse_nls(p)}
    #   puts "choices: #{choices.inspect}"
    #   set_state(STATE_KEY, get_volume, LONG_EXPIRES)
    # end

    # def choices
    #   is_expired?(STATE_KEY) ? nil : get_state(STATE_KEY)
    # end

    class ListItem

      INFO_TYPES = { "0" => "Playing", "A" => "Artist", "B" => "Album", 
        "F" => "Folder", "M" => "Music", "P" => "Playlist", "S" => "Search",
        "a" => "Account", "b" => "Playlist", "C" => "Starred", 
        "c" => "Starred", "d" => "Unstarred", "e" => "What\'s New",
        "T" => "Track" #added by J.B.M.
      }

      attr_accessor :title, :the_album, :the_artist, :extra, :type, :index, :raw_text

      def initialize(i, info_type_code, raw_text)
        self.type = INFO_TYPES[info_type_code] || "(#{info_type_code})"
        self.index = i
        self.raw_text = raw_text

        if type == "Artist"
          self.the_artist = raw_text.split(" \xC2\xB7 ")
        elsif type == "Album"
          self.the_album, self.the_artist = raw_text.split(" \xC2\xB7 ")
        elsif type == "Track"
          self.title, self.the_album, self.the_artist, *self.extra = raw_text.split(" \xC2\xB7 ")
        else
          self.extra = raw_text #.gsub("\xC2\xB7", " | ") #·
        end
      end

      def text
        if type == "Artist"
          the_artist
        elsif type == "Album"
          "#{the_album} by #{the_artist}"
        elsif type == "Track"
          "#{title} by #{the_artist} on #{the_album}"
        else
          extra
        end
      end

      def is_a_song?
        return type == "Track"
      end

      def to_s
        "#{index}. #{ type }: #{text}"
      end
    end


  end
end

