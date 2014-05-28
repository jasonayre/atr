module Atr
  class Publisher
    include ::Celluloid

    def publish_event(event)
      ::Atr::Redis.connection.publish(event["routing_key"], Marshal.dump(event))
    end
  end
end