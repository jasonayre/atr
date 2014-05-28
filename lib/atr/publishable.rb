module Atr
  module Publishable
    extend ActiveSupport::Concern

    PUBLISHABLE_ACTIONS = ["updated", "created", "destroyed"]

    included do
      include ::ActiveModel::Dirty

      after_create :publish_created_event
      after_update :publish_updated_event
      after_destroy :publish_destroyed_event

      class << self
        attr_accessor :publication_scopes
      end

      self.publication_scopes ||= []
      self.publishable_actions ||= []

      ::Atr::Publishable::PUBLISHABLE_ACTIONS.each do |action|
        ::Atr::Registry.channels << "#{routing_key}.#{action}" unless ::Atr::Registry.channels.include?("#{routing_key}.#{action}")
      end
    end

    private

    def publish_updated_event
      routing_key = self.class.build_routing_key_for_record_action(self, "updated")
      event_name = self.class.resource_action_routing_key("updated")
      record_updated_event = ::Atr::Event.new(routing_key, event_name, self)

      ::Atr.publish_event(record_updated_event)
    end

    def publish_created_event
      routing_key = self.class.build_routing_key_for_record_action(self, "created")
      event_name = self.class.resource_action_routing_key("created")
      record_created_event = ::Atr::Event.new(routing_key, event_name, self)

      ::Atr.publish_event(record_created_event)
    end

    def publish_destroyed_event
      routing_key = self.class.build_routing_key_for_record_action(self, "destroyed")
      event_name = self.class.resource_action_routing_key("destroyed")
      record_destroyed_event = ::Atr::Event.new(routing_key, event_name, self)

      ::Atr.publish_event(record_destroyed_event)
    end

    module ClassMethods
      def publishable_actions(*actions)
        @publishable_actions = actions
      end

      def routing_key
        resource_routing_keys.join(".")
      end

      def resource_routing_keys
        name.split("::").map(&:underscore)
      end

      def resource_action_routing_keys(action_routing_key)
        [resource_routing_keys, action_routing_key]
      end

      def resource_action_routing_key(action_routing_key)
        resource_action_routing_keys(action_routing_key).join(".")
      end

      def build_routing_key_for_record_action(record, action_routing_key)
        publication_scope_routing_keys = build_publication_scope_for_record(record)
        [publication_scope_routing_keys, resource_routing_keys, action_routing_key].flatten.join(".")
      end

      def build_publication_scope_for_record(record)
        publication_scopes.map do |arg|
          key = arg.to_s.split("_id").first
          value = record.__send__(arg)
          [key, value]
        end.try(:flatten)
      end

      def publication_scope(*args)
        self.publication_scopes = args
      end

      def scope_publication?
        publication_scopes.present?
      end
    end
  end
end