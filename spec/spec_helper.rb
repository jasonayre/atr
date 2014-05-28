require 'rubygems'
require 'bundler'
require 'simplecov'
require 'pry'

SimpleCov.start do
  add_filter '/spec/'
end

Bundler.require(:default, :development, :test)

::Dir["#{::File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f }