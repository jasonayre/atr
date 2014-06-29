require 'rails/railtie'

module Atr
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      ::Atr::Publisher.supervise_as :atr_publisher
    end

    ::ActiveSupport.on_load(:atr) do
      puts "ATR LOADED"
      ::Atr::Redis.connect unless ::Atr::Redis.connected?
    end
  end
end