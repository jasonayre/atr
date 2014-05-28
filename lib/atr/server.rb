require 'reel'

class Atr::Server < Reel::Server::HTTP
  def initialize(host = "127.0.0.1", port = 7777)

    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    connection.each_request do |request|
      if request.websocket?
        if ::Atr.config.authenticate_with?
          return unless ::Atr.config.authenticate_with.new(request).matches?
        end

        connection.detach

        puts "NUMBER OF CONNECTIONS"
        ::ActiveRecord::Base.clear_active_connections!
        puts ::ActiveRecord::Base.connection_pool.instance_variable_get("@connections").size

        puts "NUMBER OF ACTORS"
        puts ::Celluloid::Actor.all.count

        if ::Atr.config.scope_with?
          routing_scope = ::Atr.config.scope_with.new(request)

          return unless routing_scope.valid?

          ::Atr::Reactor.new(request.websocket, routing_scope.routing_key)
        else
          ::Atr::Reactor.new(request.websocket)
        end

        return
      else
        handle_request(request)
      end
    end
  end

  def handle_request(request)
    request.respond :ok, "Nothing to see here"
  end

  def handle_websocket(socket)
    ::Atr::Reactor.new(socket)
  end
end