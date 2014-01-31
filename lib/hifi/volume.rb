module Hifi
  module Volume

    STATE_KEY = "volume"
    PARAMS = ["MVL"]

    def self.get_params
      PARAMS
    end

    def self.parse_param(param, _, hifi)
      return if param == "N/A"
      current_volume = param.to_i(16)
      puts "Current volume: #{current_volume}"
      hifi.set_state(STATE_KEY, current_volume)
    end

    def volume_up
      cmd("MVL", "UP")
    end

    def volume_down
      cmd("MVL", "DOWN")
    end

    def get_volume
      cmd("MVL", "QSTN")
      nil
    end

    def volume=(lvl)
      return if lvl.nil?
      raise ArgumentError, "Invalid volume, must be between 0 and 100" if lvl > 100 || lvl < 0
      lvl_str = lvl.to_s(16)
      if lvl_str.size == 1 #hex volume number needs to padded to size 2
        lvl_str = "0#{lvl_str}"
      end
      cmd("MVL", lvl_str.upcase)
    end


    # def get_volume
    #   mode_code = cmd("MVL", "QSTN").parameter
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

    #used only internally, e.g. if another module needs to see if it needs to turn the volume up or down.
    def volume
      get_state(STATE_KEY)
    end


  end
end