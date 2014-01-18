require_relative 'hifi/evceiver'
require_relative '../../onkyo_eiscp_ruby/lib/eiscp'
require_relative 'hifi/sources'
require_relative 'hifi/volume'
require_relative 'hifi/controllable'
require_relative 'hifi/radio'
require_relative 'hifi/spotify'
require 'socket'
require 'thread'
require 'eventmachine'

module Hifi

  class Hifi 
    # include Sources
    # include Volume
    # include Radio
    # include Controllable
    # include Spotify

    ONKYO_MAGIC = EISCP::Message.new("ECN", "QSTN", "x").to_eiscp
    ONKYO_PORT = 60128

    PLAYING = 1
    PAUSED = 0
    STOPPED = -1
    STALENESS = 60 #seconds

    def initialize(rec=nil) #an EISCP object
      @state = {}
      @volume = Volume.new(self)
    end

    def parse(command)
      #returns lambdas!
      if command == "MVL"
        lambda{|param| @volume.parse(param) }
      else
        puts "parser recieved: #{command}"
        lambda{|a| }
      end
    end

    # Returns an array of arrays consisting of a discovery response packet string
    # and the source ip address of the reciever.

    def Hifi.discover
      sock = UDPSocket.new
      sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      sock.send(ONKYO_MAGIC, 0, '<broadcast>', ONKYO_PORT)
      data = []
      while true
        ready = IO.select([sock], nil, nil, 0.5)
        if ready != nil
          then readable = ready[0]
        else
          return data
        end


        readable.each do |socket|
          begin
            if socket == sock
              msg, addr = sock.recvfrom_nonblock(1024)
              data << [msg, addr[2]]
            end
          rescue IO::WaitReadable
            retry
          end
        end

      end
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


    # private
    # def send_without_confirmation(command, val)
    #   raw_cmd(command, val)
    #   nil
    # end

    def raw_cmd(command, val)
      eiscp_packet = EISCP::Message.new(command, val.to_s) 
      eiscp_packet
    end
    # alias_method :cmd, :raw_cmd

    # def parse_responses(resps)
    #   return [] if resps.nil?
    #   valid_resps = resps.map{|resp| EISCP::Message.parse(resp) }.compact
    #   valid_resps
    # end

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


ips = Hifi::Hifi.discover
if ips.empty?
  raise IOError, "No Onkyo receivers found!"
end
ip = ips[0][1]

h = Hifi::Hifi.new

myq = Queue.new

Thread.new do
  EM.run do
    @emq = EM::Queue.new
    @emq.push( h.raw_cmd("PWR", "QSTN") )
    EventMachine.connect ip, Hifi::Hifi::ONKYO_PORT, Hifi::Evceiver, @emq, myq, h
   end
end.join(1) # the join just waits a second to let EM spin up, if something fails, it'll bring the error back into the main thread

# @emq.push( h.raw_cmd("MVL", "QSTN") )
# @emq.push( h.raw_cmd("MVL", "QSTN") )
@emq.push( h.raw_cmd("MVL", "QSTN") )
sleep 20
@emq.push( h.volume ) ) #hex, so that's 32

#puts myq.pop
puts "sl"
sleep 5
puts "eep"



# require 'thread'
# require 'eventmachine'

# Thread.new do
#   EM.run do
#     EventMachine.connect ip, Hifi::Hifi::ONKYO_PORT, Hifi::Evceiver
#    end
# end.join(1) # the join just waits a second to let EM spin up, if something fails, it'll bring the error back into the main thread

# emq = EM::Queue.new
# thq = Queue.new

# # # This is the setup to accept jobs on the emq. So to run a job in a 'blocking'
# # # way, we will send a job that must unblock the thq when it's done, then we will
# # # block on thq.pop:

# work_and_pop = lambda do |emjob|
#   emjob.call
#   emq.pop(work_and_pop)
# end
# emq.pop(work_and_pop)

# sleep(5)

# emq.push(lambda { EM.add_timer(1) { thq.push('hello world') } })
# puts thq.pop
