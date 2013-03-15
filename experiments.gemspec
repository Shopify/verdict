# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'experiments/version'

Gem::Specification.new do |gem|
  gem.name          = "experiments"
  gem.version       = Experiments::VERSION
  gem.authors       = ["Shopify"]
  gem.email         = ["developers@jadedpixel.com"]
  gem.description   = %q{Shopify Experiments classes}
  gem.summary       = %q{Models used to define experiments used to A/B test Shopify applications.}
  gem.homepage      = "http://github.com/Shopify/experiments"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency "rails", "~> 3.2"

  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
end
