require "atr/version"

require "celluloid"
require "reel"
require "active_support"
require 'active_support/concern'
require "active_attr"

require "atr/config"
require "atr/event"
require "atr/reactor"
require "atr/server"
require "atr/redis"
require "atr/request_authenticator"
require "atr/request_scope"
require "atr/publishable"
require "atr/publisher"
require "atr/registry"

module Atr
  class << self
    attr_accessor :configuration
    alias_method :config, :configuration
  end

  def self.publish_event(event)
    ::Celluloid::Actor[:atr_publisher].publish_event(event)
  end

  def self.channels
    ::Atr::Registry.channels
  end

  def self.configure
    self.configuration ||= ::Atr::Config.new

    yield(configuration)

    ::ActiveSupport.run_load_hooks(:atr, self)
  end

  def self.configured?
    respond_to?(:configuration)
  end
end

require 'atr/railtie' if defined?(Rails)
