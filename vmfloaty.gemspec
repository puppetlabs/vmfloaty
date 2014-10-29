require File.expand_path '../lib/vmfloaty/version', __FILE__

Gem::Specification.new do |s|
  s.name = 'vmfloaty'
  s.version = Vmfloaty::CLI::VERSION.dup
  s.authors = ['Brian Cain']
  s.email = ['brian.cain@puppetlabs.com']
  s.license = 'Apache'
  s.homepage = 'https://github.com/briancain/vmfloaty'
  s.description = 'A helper tool for vmpooler to help you stay afloat'
  s.summary = 'CLI application to interface with vmpooler'
  s.executables = ['floaty']
  s.files = Dir['LICENSE', 'README.md', 'lib/**/*']
  s.test_files = Dir['spec/**/*']
  s.require_path = 'lib'
  s.add_dependency 'thor', '~> 0.19'
end
