require File.expand_path('../lib/c64/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Lars Haugseth"]
  gem.email         = ["c64-ruby@larshaugseth.com"]
  gem.description   = %q{Ruby library and tools for Commodore 64 development}
  gem.summary       = %q{Ruby library and tools for Commodore 64 development}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "c64-ruby"
  gem.require_paths = ["lib"]
  gem.version       = C64::VERSION

  gem.add_dependency "chunky_png", "~> 1.2.7"

  gem.add_development_dependency "pry", "~> 0.9.12"
end
