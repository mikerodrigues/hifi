require 'eventmachine'
require 'eiscp/parser'

module Hifi
  class Evceiver < EventMachine::Connection
    attr_reader :queue

    def initialize(q, hifi)
      @hifi = hifi || Hifi.new
      @queue = q

      cb = Proc.new do |msg|
        send_data(msg)
        @queue.pop &cb
      end

      @queue.pop &cb
    end

    def post_init
      @buffer = ""
    end

    def receive_data(data)
      # puts "Received (#{data.size}):'#{data.inspect}';"
      # hifi.parse_responses(data)
      # emq
      @buffer << data
      msgs = parse_buffer
      msgs.each do |msg|
        # puts msg.inspect
        begin
          @hifi.parse(msg).call(msg.value)
        rescue Exception => e
          puts "Error:  #{msg.inspect}\n#{e.message}\n#{e.backtrace.join("\n")};"
        end
      end
    end

    def parse_buffer
      *msgs, @buffer = @buffer.split("\x1A\r\n", -1) #TODO: there are other EOF sequences
      msgs.map{|resp| EISCP::Parser.parse(resp) }
    end

    def send_data(data)
      puts "Sent #{@queue.size}: '#{data.to_eiscp.to_s.inspect}';"
      super(data.to_eiscp + "\n")
    end

    def unbind
      stop
    end
  end
end
#   class Evceiver < EventMachine::Connection

#     # attr_accessor :host
#     # attr_accessor :model
#     # attr_accessor :port
#     # attr_accessor :area
#     # attr_accessor :mac_address

#     # Create a new EISCP object to communicate with a receiver.

#     # def initialize(host, hifi)
#     #   @host, port = host.split(":")
#     #   @port = port.nil? ? ONKYO_PORT : port
#     #   @hifi = hifi
#     # end
#     def post_init
#       @buffer = ""
#     end

#     def receive_data(data)
#       puts "Received (#{data.size}):'#{data.inspect}';"
#       # hifi.parse_responses(data)
#       # emq
#       @buffer << data
#       msgs = parse_buffer
#       msgs.each do |msg|
#         puts msg.inspect

#       end
#     end

#     def parse_buffer
#       *msgs, @buffer = @buffer.split("\x1A\r\n", -1) #TODO: there are other EOF sequences
#       msgs.map{|resp| EISCP::Message.parse(resp) }
#     end

#     def send_data(data)
#       puts "Sent (#{data.to_eiscp.size}): '#{data.to_eiscp}';"
#       super(data.to_eiscp)
#     end

#     def unbind
#       stop
#     end
#   end
# end
