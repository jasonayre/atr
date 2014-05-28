require 'reel'

module Atr
  class Reactor
    include Celluloid
    include Celluloid::IO
    include Celluloid::Logger

    attr_accessor :websocket
    attr_accessor :routing_key_scope
    attr_accessor :subscribers

    def initialize(websocket, routing_key_scope = nil)
      info "Streaming changes"

      @routing_key_scope = routing_key_scope
      @websocket = websocket

      @subscribers = ::Atr::Registry.scoped_channels(routing_key_scope).map do |channel|
        async.start_subscriber(channel)
      end

      async.run
    end

    def dispatch_message(message)
      puts message.inspect
    end

    def run
      while message = @websocket.read
        if message == "unsubscribe"
          unsubscribe_all
        else
          dispatch_message(message)
        end
      end
    end

    #todo: decide between starting individually or subscribing all at once and remove one of the methods
    def start_subscribers
      ::Atr::Redis.connect unless ::Atr::Redis.connected?

      ::Atr::Redis.connection.subscribe(::Atr::Registry.scoped_channels(routing_key_scope)) do |on|
        on.subscribe do |channel, subscriptions|
          puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.unsubscribe do |channel, subscriptions|
          ::ActiveRecord::Base.clear_active_connections!
          terminate
        end

        on.message do |channel, message|
          shutdown if message == "exit"

          event = Marshal.load(message)

          if ::Atr.config.event_serializer?

            websocket << ::Atr.config.event_serializer.new(event).to_json
          else
            websocket << event.to_json
          end
        end
      end
    rescue Reel::SocketError
      info "Client disconnected"
      ::ActiveRecord::Base.clear_active_connections!
      terminate
    end

    def shutdown
      ::Atr::Redis.connection.unsubscribe
      ::ActiveRecord::Base.clear_active_connections!
      terminate
    end

    def start_subscriber(channel)
      ::Atr::Redis.connect unless ::Atr::Redis.connected?

      ::Atr::Redis.connection.subscribe(channel) do |on|
        on.subscribe do |channel, subscriptions|
          puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.unsubscribe do |channel, subscriptions|
          puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
          ::ActiveRecord::Base.clear_active_connections!
          terminate
        end

        on.message do |channel, message|
          shutdown if message == "exit"

          event = Marshal.load(message)

          if ::Atr.config.event_serializer?
            puts "FOUND SERIUALIZER"
            puts ::Atr.config.event_serializer.inspect
            puts ::Atr.config.event_serializer.new(event).to_json
            websocket << ::Atr.config.event_serializer.new(event).to_json
          else
            websocket << event.to_json
          end
        end
      end
    end

    def unsubscribe_all
      ::Atr::Registry.scoped_channels(routing_key_scope).map do |channel|
        ::Atr::Redis.connection.unsubscribe(channel)
      end

      info "clearing connections"
      terminate
    end
  end
end