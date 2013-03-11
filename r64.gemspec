require File.expand_path('../lib/r64/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Lars Haugseth"]
  gem.email         = ["gem-r64@larshaugseth.com"]
  gem.description   = %q{Ruby library and tools for Commodore 64 development}
  gem.summary       = %q{Ruby library and tools for Commodore 64 development}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "r64"
  gem.require_paths = ["lib"]
  gem.version       = R64::VERSION

  gem.add_dependency "chunky_png", "~> 1.2.7"
  gem.add_dependency "oily_png", "~> 1.1.0"

  gem.add_development_dependency "pry"
end
