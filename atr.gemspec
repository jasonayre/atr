# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atr/version'

Gem::Specification.new do |spec|
  spec.name          = "atr"
  spec.version       = Atr::VERSION
  spec.authors       = ["Jason Ayre"]
  spec.email         = ["jasonayre@gmail.com"]
  spec.summary       = %q{Pub, sub and websocket server}
  spec.description   = %q{Pub sub and websockets}
  spec.homepage      = "http://github.com/jasonayre/atr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "active_attr"
  spec.add_dependency "reel", "> 0.4.0"
  spec.add_dependency "redis"
  spec.add_dependency "celluloid-io"
  spec.add_dependency "celluloid-redis"
  spec.add_dependency "json"

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-pride"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "simplecov"
end
