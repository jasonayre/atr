module Atr
  class Publisher
    include ::Celluloid

    def publish_event(event)
      ::ActiveRecord::Base.connection_pool.with_connection do
        ::Atr::Redis.connection.publish(event["routing_key"], Marshal.dump(event))
      end
    end
  end
end