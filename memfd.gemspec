lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memfd/version'

Gem::Specification.new do |s|
  s.name = "memfd"
  s.version = MemFD::VERSION
  s.summary = "Ruby interface to the memfd_create() syscall for creating anonymous in memory files"
  s.description = "Ruby interface to the memfd_create() syscall for creating anonymous in memory files"
  s.authors = ["Bear Metal"]
  s.email = ["info@bearmetal.eu"]
  s.license = "MIT"
  s.homepage = "https://github.com/bear-metal/memfd"
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extensions = "ext/memfd/extconf.rb"
  s.test_files = `git ls-files test`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.1.0'

  s.add_development_dependency('rake-compiler', '~> 1.0.4')
  s.add_development_dependency('minitest', '~> 5.10.2')
end