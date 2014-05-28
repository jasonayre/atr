require 'redis'
require 'celluloid/redis'
require 'redis/connection/celluloid'

module Atr
  class Redis
    class << self
      @connected ||= false
      attr_accessor :connected, :connection

      alias_method :connected?, :connected
    end

    def self.connect(options={})
      @connection = ::Redis.new(:driver => :celluloid)
    end
  end
end