

module Hifi

  class Source
    attr_reader :code, :name
    def initialize(code, name, controllable)
      @code = code
      @name = name
      @controllable = controllable
    end
    def controllable?
      @controllable
    end
    def ==(other)
      self.name = other.name
    end
    def to_s
      name
    end
    def inspect
      "<Source name: #{name}, code: #{code}, controllable: #{controllable?} >"
    end
  end


  module Sources
    SOURCES = [
      Source.new("22", "Phono", false),
      Source.new("24", "FM", false),
      Source.new("25", "AM", false),
      Source.new("2B", "Net", true),
      Source.new('', "Unknown Source", true)
    ]
    STATE_KEY = "source"

    def source=(mode_name)
      s = SOURCES.find{|s| s.name.upcase == mode_name.upcase }
      cmd("SLI", s.code)
    end

    def raw_source=(mode_code)
      cmd("SLI", mode_code)
    end

    def raw_source
      resp = cmd("SLI", "QSTN")
      mode_code = resp.parameter
      mode_code
    end

    def source
      is_expired?(STATE_KEY) ? set_state(STATE_KEY, get_source) :  get_state(STATE_KEY)
    end

    def get_source
      puts "getting source via network"
      mode_code = raw_source || ''
      @last_source_check = Time.now
      SOURCES.find{|s| s.code.upcase == mode_code.upcase }
    end

  end
end