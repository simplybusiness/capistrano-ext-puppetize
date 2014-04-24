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
  end
end

describe Capistrano::Puppetize::Config do
  it 'supports customizing the module path' do
    values = {
      variables: {black: "white",
        bark: "bite",
        shark: "Hey man, Jaws was never my scene"
      },
      puppet_root: "/home/runner/app/current/config/puppet",
      project_root: "/home/runner/app/current/",
      module_paths: ["/etc/puppet/modules",
                     "/tmp/modules"]
    }
    config = Capistrano::Puppetize::Config.new(values)
    script = config.apply_sh
    expect(script).to match %{--modulepath=/etc/puppet/modules:/tmp/modules:/home/runner/app/current/config/puppet/modules:/home/runner/app/current/config/puppet/vendor/modules}
  end


end
