require 'redis'
require 'celluloid/redis'
require 'redis/connection/celluloid'

module Atr
  class Redis
    class_attribute :connection
    class_attribute :connection_pool

    def self.connect
      self.connection ||= ::Redis.new(::Atr.configuration.redis)

      self.connection_pool ||= ::ConnectionPool.new(:size => ::Atr.configuration.publisher_pool_size) do
        ::Atr::Redis.connection
      end
    end

    def self.connected?
      connection?
    end
  end
end