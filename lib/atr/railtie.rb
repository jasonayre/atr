require 'rails/railtie'

module Atr
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      ::Atr::Redis.connect unless ::Atr::Redis.connected?

      ::Atr::Publisher.supervise_as :atr_publisher
    end

    ::ActiveSupport.on_load(:atr) do
      puts "ATR LOADED"
    end

    #todo: make redis configurable
    def self.load_config_yml
      config_file = ::YAML.load_file(config_yml_filepath)
      return unless config_file.is_a?(Hash)
    end

    def self.config_yml_exists?
      ::File.exists? config_yml_filepath
    end

    def self.config_yml_filepath
      ::Rails.root.join('config', 'atr.yml')
    end
  end
end