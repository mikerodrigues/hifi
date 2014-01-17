module Hifi
  module Controllable
    def play
      check_source!
      send_without_confirmation("NTC", "PLAY")
    end
    def playpause
      check_source!
      send_without_confirmation("NTC", play_status != PLAYING ? "PLAY" : "PAUSE" )
    end
    def pause
      check_source!
      send_without_confirmation("NTC", "PAUSE")
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
      cmd("NSB", "OFF")
    end
    def on
      cmd("NSB", "ON")
    end

    def check_source!
      raise NoMethodError, "The current source isn't controllable." unless source.controllable?
    end 
  end
end
