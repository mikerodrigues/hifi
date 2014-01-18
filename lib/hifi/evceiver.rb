require 'eventmachine'
require_relative '../../../onkyo_eiscp_ruby/lib/eiscp/message'

module Hifi
  class Evceiver < EventMachine::Connection
    attr_reader :queue

    def initialize(q, other_q, hifi)
      @hifi = hifi || Hifi.new
      @queue = q
      @resp_queue = other_q

      cb = Proc.new do |msg|
        send_data(msg)
        q.pop &cb
      end

      q.pop &cb
    end

    def post_init
      @buffer = ""
    end

    def receive_data(data)
      puts "Received (#{data.size}):'#{data.inspect}';"
      # hifi.parse_responses(data)
      # emq
      @buffer << data
      msgs = parse_buffer
      msgs.each do |msg|
        puts msg.inspect
        @hifi.parse(msg.command).call(msg.parameter)
        @resp_queue.push(msg.inspect)
      end
    end

    def parse_buffer
      *msgs, @buffer = @buffer.split("\x1A\r\n", -1) #TODO: there are other EOF sequences
      msgs.map{|resp| EISCP::Message.parse(resp) }
    end

    def send_data(data)
      puts "Sent (#{data.to_eiscp.size}): '#{data.to_eiscp.to_s.inspect}';"
      super(data.to_eiscp)
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