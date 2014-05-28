module Atr
  class Registry
    include ActiveSupport::Configurable

    class << self
      attr_accessor :channels
    end

    @channels = []

    def self.scoped_channels(routing_key)
      channels.map{ |channel| "#{routing_key}.#{channel}" }
    end
  end
end