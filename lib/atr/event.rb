require 'active_model'
module Atr
  class Event
    include ::ActiveAttr::Model
    include ::ActiveModel::AttributeMethods

    attribute :id
    attribute :name
    attribute :occured_at
    attribute :record
    attribute :record_type
    attribute :routing_key

    def initialize(routing_key, name, record)
      self[:id] = rand(1000)
      self[:routing_key] = routing_key
      self[:name] = name
      self[:record] = record.attributes
      self[:record_type] = record.class.name
      self[:occured_at] = ::DateTime.now
    end
  end
end