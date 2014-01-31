module Hifi
  module Controllable

    PARAMS = ["NTC", "NSB", "PWR"]

    def self.get_params
      PARAMS
    end


    def play
      check_source!
      cmd("NTC", "PLAY")
    end
    def playpause
      check_source!
      cmd("NTC", play_status != PLAYING ? "PLAY" : "PAUSE" )
    end
    def pause
      check_source!
      cmd("NTC", "PAUSE")
    end
    def next_track
      check_source!
      cmd("NTC", "TRUP")
    end
    def prev_track
      check_source!
      cmd("NTC", "TRDN")
    end

    def repeat
      check_source!
      raise NotYetImplementedError
    end
    def shuffle
      check_source!
      raise NotYetImplementedError
    end

    #need status info
    def off
      cmd("PWR", "00")
    end
    def on
      cmd("PWR", "01")
      pause if source.controllable?
    end
    alias_method :standby, :off

    def check_source!
      raise UncontrollableSourceError, "The current source isn't controllable." unless source.controllable?
    end 
  end
end
