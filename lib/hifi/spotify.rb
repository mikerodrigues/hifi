module Hifi
  module Spotify
    include Controllable
    STATE_KEY = "NLS"
    LONG_EXPIRES = 60 * 20


    def parse_nls(param)
      matchobj = nls.match(/U(?<index>\d)P(?<val>.*)/)
      [matchobj["index"], matchobj["val"]]
    end

    def read_nls_list(resps) # (this used to send an empty req. dunno if that's useful.)
      parsed_resps = parse_responses(resps)
      parsed_resps.select!{|resp| resp.command == "NLS"}
      choices = parsed_resps.map(&:parameter).map{|p| parse_nls(p)}
      puts "choices: #{choices.inspect}"
      set_state(STATE_KEY, get_volume, LONG_EXPIRES)
    end

    def choices
      is_expired?(STATE_KEY) ? nil : get_state(STATE_KEY)
    end

    

    def select_spotify
      info =  YAML.load(open("account_info.yml", 'r').read)["spotify"]
      un = info["username"]
      pw = info["password"]
      un = un + ("\00" * (128 - un.size))
      pw = pw + ("\00" * (128 - pw.size))
      read_nls_list(raw_cmd("NSV", "0A1#{un}#{pw}" ))
    end
  end
end