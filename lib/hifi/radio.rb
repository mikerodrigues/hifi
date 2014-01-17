module Hifi
  module Radio

    def station=(freq)
      clean_freq =  if source.nil?
                      freq
                    elsif source.name == "FM" && freq.class == String
                      freq.to_i * 100
                    elsif source.name == "AM"
                      freq.to_i
                    end
      clean_freq = clean_freq.to_s
      if clean_freq.size < 5
        zeroes_needed = 5 - clean_freq.size
        clean_freq = "0" * zeroes_needed + clean_freq
      end 
      puts "setting freq to #{clean_freq}"
      cmd("TUN", clean_freq)
    end

    def get_station
      #TODO: use source too (e.g. if FM, 09310 is 93.1, but 1400 is 1400 AM )
      resp = cmd("TUN", "QSTN")
      return nil if resp.nil?
      freq = resp.parameter
      if source.nil?
        freq
      elsif source.name == "FM"
        freq.to_i * 0.1
      elsif source.name == "AM"
        freq.to_i
      end
    end

    STATE_KEY = "station"

    def station
      is_expired?(STATE_KEY) ? set_state(STATE_KEY, get_station) : get_state(STATE_KEY)
    end
  end
end 