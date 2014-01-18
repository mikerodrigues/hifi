module Hifi
  class Volume

    STATE_KEY = "volume"

    def initialize(rec)
      @rec = rec
    end

    def parse(param)
      puts "Parsing: #{param}"
      return if param == "N/A"
      volume = param.to_i(16)
      puts "Current volume: #{volume}"
    end


    def volume_up
      rec.cmd("MVL", "UP")
    end

    def volume_down
      rec.cmd("MVL", "DOWN")
    end

    def get_volume
      rec.cmd("MVL", "QSTN")
    end

    def volume=(lvl)
      return if lvl.nil?
      raise ArgumentError, "Invalid volume, must be between 0 and 100" if lvl > 100 || lvl < 0
      lvl_str = lvl.to_s(16)
      if lvl_str.size == 1 #hex volume number needs to padded to size 2
        lvl_str = "0#{lvl_str}"
      end
      rec.cmd("MVL", lvl_str.upcase)
    end

    # def volume
    #   is_expired?(STATE_KEY) ? set_state(STATE_KEY, get_volume) : get_state(STATE_KEY)
    # end

    # def get_volume
    #   mode_code = rec.cmd("MVL", "QSTN").parameter
    #   mode_code.sub!(/\x1a$/, '')
    #   mode_code.to_i(16)
    # end


    def mute
      @old_volume = volume
      volume = 0
    end

    def unmute
      @old_volume = nil
      volume = @old_volume
    end

  end
end