# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'verdict/version'

Gem::Specification.new do |gem|
  gem.name          = "verdict"
  gem.version       = Verdict::VERSION
  gem.authors       = ["Shopify"]
  gem.email         = ["kevin.mcphillips@shopify.com", "willem@shopify.com"]
  gem.description   = %q{Shopify Experiments classes}
  gem.summary       = %q{A library to centrally define experiments for your application, and collect assignment information.}
  gem.homepage      = "http://github.com/Shopify/verdict"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_development_dependency "minitest", '~> 4.2'
  gem.add_development_dependency "rake"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "timecop"
  gem.add_development_dependency "redis"
end
