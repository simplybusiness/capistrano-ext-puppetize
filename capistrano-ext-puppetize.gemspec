$:.push File.expand_path("../lib", __FILE__)

require 'capistrano/ext/puppetize/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano-ext-puppetize'
  spec.version = Capistrano::Ext::Puppetize::Version::STRING
  spec.platform = Gem::Platform::RUBY
  spec.authors = ['Simply Business']
  spec.email = ['daniel.barlow@simplybusiness.co.uk']
  spec.summary = 'Run Puppet manifests in a Capistrano deployment'
  spec.description = 'Capistrano extension to run Puppet manifests contained in the application to be deployed'
  spec.license = 'Simplified BSD'

  spec.add_dependency 'capistrano', '>=2.0.0'
  spec.add_dependency 'capistrano-ext'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'capistrano-spec'

  spec.require_path = 'lib'
end
