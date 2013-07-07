require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Capistrano::Puppetize, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    @configuration.extend(Capistrano::Puppetize)
    Capistrano::Puppetize.load_into(@configuration)
  end

  describe 'puppet namespace' do
    before do
      @configuration.set(:deployer, "JC Denton")
      @configuration.set(:application, "daedalus")
      @configuration.set(:branch, "master")
      @configuration.set(:stage, "staging")
      @configuration.set(:current_release, "/for/bar/current")
      @configuration.set(:app_host_name, "Helios")
    end

    it "defines puppet:install" do
      @configuration.find_and_execute_task('puppet:install')
      @configuration.find_task('puppet:install').should_not eql nil
    end

    it "performs puppet:install before deploy:finalize_update" do
      @configuration.should callback('puppet:install').before('deploy:finalize_update')
    end

    it 'should create the puppet file and run it' do
      @configuration.find_and_execute_task('puppet:install')
      @configuration.should have_run("chmod a+x /etc/puppet/apply")
      @configuration.should have_run("sudo /etc/puppet/apply")
    end

    it 'calls preload_exported_puppet_vars' do
      @configuration.should_receive(:preload_exported_puppet_vars)
      @configuration.find_and_execute_task('puppet:install')
    end

  end

  describe '#preload_exported_puppet_vars' do
    it 'evaluates variables that are in :exported_to_puppet var' do
      @configuration.set(:biz, lambda { 'evaluated' })
      @configuration.set(:foo, lambda { 'evaluated_2' })
      @configuration.set(:exported_to_puppet, [:biz, :foo])

      @configuration.preload_exported_puppet_vars.should include 'evaluated'
      @configuration.preload_exported_puppet_vars.should include 'evaluated_2'
    end
  end

end
