require_relative '../../onkyo_eiscp_ruby/lib/eiscp'
require_relative 'hifi/sources'
require_relative 'hifi/volume'
require_relative 'hifi/controllable'
require_relative 'hifi/radio'
require_relative 'hifi/spotify'

module Hifi
  class Hifi
    include Sources
    include Volume
    include Radio
    include Controllable
    include Spotify

    PLAYING = 1
    PAUSED = 0
    STOPPED = -1
    STALENESS = 60 #seconds

    def initialize(rec=nil) #an EISCP object
      if rec.nil?
        ips = EISCP::Receiver.discover
        if ips.empty?
          raise IOError, "No Onkyo receivers found!"
        end
        ip = ips[0][1]
        @rec = EISCP::Receiver.new(ip)
      else
        @rec = rec
      end
      @state = {}
    end

    # consumers of state information have to get it from the Hifi object
    # the Hifi object arbitrates whether to send them saved state info
    # or refresh it from the source of the state info.
    # However, modules should transparently be the ones fetching (so #volume is still okay)

    def refresh_basic_state
      @source = source
      @volume = volume
      if @source.controllable?
        @play_status = STOPPED
      end
    end

    def set_state(k, v, custom_expires=STALENESS)
      @state[k] ||= {}
      @state[k][:result] = v
      @state[k][:expires] = Time.now - (custom_expires - STALENESS)
      v
    end
    def get_state(k)
      @state[k][:result]
    end
    def get_state_expires(k)
      @state[k][:expires]
    end
    def is_expired?(k)
      @state[k].nil? || (Time.now - @state[k][:expires]) > STALENESS
    end


    private
    def send_until_confirmed(command, val, allowable_tries=3)
      tries ||= allowable_tries

      begin
        resps = raw_cmd(command, val)
        parsed = parse_responses(resps)
        resp = parsed.find{|resp| resp.command == command}
        if resp.nil?
          raise NoResponseError
        end
      rescue NoResponseError
        if (tries -= 1).zero?
          resp = EmptyMessage.new
        else 
          retry
        end 
      end
      resp
    end
    alias_method :cmd, :send_until_confirmed

    def send_without_confirmation(command, val)
      raw_cmd(command, val)
      nil
    end

    def raw_cmd(command, val)
      puts "sending: #{command} -> #{val}"
      eiscp_packet = EISCP::Message.new(command, val.to_s) 
      @rec.send_recv(eiscp_packet)
    end

    def parse_responses(resps)
      return [] if resps.nil?
      valid_resps = resps.map{|resp| EISCP::Message.parse(resp) }.compact
      valid_resps
    end

    # def debounce(method_name, *args)
    #   @debounced ||= {}
    #   unless @debounced[method_name] && (Time.now - @debounced[method_name][:time] > 60)
    #     @debounced[method_name] = {
    #         :time => Time.now,
    #         :result => send(method_name.to_sym, args)
    #     }
    #   end
    #   @debounced[method_name][:result]
    # end

  end
  class NotYetImplementedError < Exception; end
  class NoResponseError < Exception; end
  class EmptyMessage
    def parameter
      nil
    end
  end
end
