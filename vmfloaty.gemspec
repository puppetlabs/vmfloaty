# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'vmfloaty/version'

Gem::Specification.new do |s|
  s.name = 'vmfloaty'
  s.version = Vmfloaty::VERSION
  s.authors = [
    'Brian Cain',
    'Puppet',
  ]
  s.email = [
    'brianccain@gmail.com',
    'dio-gems@puppet.com',
  ]
  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/puppetlabs/vmfloaty'
  s.description = 'A helper tool for vmpooler to help you stay afloat'
  s.summary = 'CLI application to interface with vmpooler'

  s.executables = ['floaty']
  s.files = Dir['LICENSE', 'README.md', 'lib/**/*', 'extras/**/*']
  s.test_files = Dir['spec/**/*']
  s.require_path = 'lib'

  s.add_dependency 'colorize', '~> 0.8.1'
  s.add_dependency 'commander', '>= 4.4.3', '< 4.6.0'
  s.add_dependency 'faraday', '~> 0.17.0'
end
