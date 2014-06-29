module Atr
  class Publisher
    include ::Celluloid

    def publish_event(event)
      ::ActiveRecord::Base.connection_pool.with_connection do
        puts event.inspect
        ::Atr::Redis.connection.publish(event["routing_key"], Marshal.dump(event))
        # ::Atr::Redis.connection_pool.with do |connection|
        #   puts event.inspect
        #   connection.publish(event["routing_key"], Marshal.dump(event))
        # end
      end
    end
  end
end