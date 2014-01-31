

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
      #Source.new("") #aux #TODO
      Source.new('', "Unknown Source", true)
    ]
    STATE_KEY = "source"
    PARAMS = ["SLI"]

    def self.get_params
      PARAMS
    end


    def self.parse_param(param, _, hifi)
      return if param == "N/A"
      current_source = SOURCES.find{|s| s.code.upcase == param.upcase }
      puts "Current source: #{current_source}"
      hifi.set_state(STATE_KEY, current_source)
    end


    def source=(mode_name)
      s = SOURCES.find{|s| s.name.upcase == mode_name.upcase }
      cmd("SLI", s.code)
      begin
        pause
      rescue UncontrollableSourceError => e
        #it's okay.
      end
      nil
    end

    def raw_source=(mode_code)
      cmd("SLI", mode_code)
      nil
    end


    def get_source
      cmd("SLI", "QSTN")
      nil
    end

    def source
      get_state(STATE_KEY)
    end


  end
end