require 'active_support/ordered_options'

module Atr
  class Config < ::ActiveSupport::OrderedOptions
    def initialize(options = {})
      options[:redis] = {
        :host => '127.0.0.1',
        :port => '6379',
        :driver => :celluloid
      }

      options[:publisher_pool_size] ||= 25

      super
    end

    def authenticate?
      has_key?(:authenticate_with)
    end

    def scope?
      has_key?(:scope_with)
    end

    def event_serializer?
      has_key?(:event_serializer)
    end

    def serialize_events_with?
      has_key?(:serialize_events_with)
    end
  end
end