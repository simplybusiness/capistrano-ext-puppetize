require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Capistrano::Puppetize::Config do
  it 'complains if required args are missing' do
    values = {
      variables: {},
      project_root: "/home/runner/app/current/",
      module_paths: ["/etc/puppet/modules",
                     "/tmp/modules"]
    }
    expect {
      Capistrano::Puppetize::Config.new(values)
    }.to raise_error KeyError
  end

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

  it 'expects fileserver.conf in the git working tree' do
    values = {
      variables: {starwars: "Dislike",
        wrong: "right",
        god: "Gimme a choice"
      },
      puppet_root: "/home/runner/app/current/config/puppet",
      project_root: "/home/runner/app/current/",
      module_paths: []
    }
    config = Capistrano::Puppetize::Config.new(values)
    script = config.apply_sh
    expect(script).to match %{--fileserverconfig=/home/runner/app/current/config/puppet/fileserver.conf}
  end
end
