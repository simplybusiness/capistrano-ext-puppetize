require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'capistrano/puppetize/config'
# require 'capistrano-spec'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
  config.tty = true
  config.formatter = :documentation
  # config.include Capistrano::Spec::Matchers
  # config.include Capistrano::Spec::Helpers
end
