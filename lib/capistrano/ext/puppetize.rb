require 'capistrano'
module Capistrano
  module Puppetize
    def self.load_facts(variables)
      variables.find_all { |k, v| v.is_a?(String) }.
        map {|k, v| "FACTER_cap_#{k}=#{v.inspect}" }.
      join(" ")
    end

    def self.load_into(configuration)
      configuration.load do
        before "deploy:finalize_update", "puppet:install"

        def self.preload_exported_puppet_vars
          Array(fetch(:exported_to_puppet, [])).map { |k| fetch(k) }
        end

        namespace :puppet do
          desc "Install and run puppet manifests"
          task :install do
            preload_exported_puppet_vars
            # Export capistrano variables as Puppet facts so that the
            # site.pp manifest can make decisions on what to install based
            # on its role and environment.  We only export string variables
            # -- not class instances, procs, and other outlandish values
            facts = Puppetize.load_facts(variables)

            puppet_location = fetch(:puppet_install_dir, "/etc/puppet")

            # create puppet/fileserver.conf from given puppet file location
            puppet_d= fetch(:project_puppet_dir, "#{current_release}/config/puppet")
            put(<<FILESERVER, "#{puppet_d}/fileserver.conf")
[files]
  path #{puppet_d}/files
  allow 127.0.0.1
[root]
  path #{current_release}\n  allow 127.0.0.1
FILESERVER
            # A puppet run can be started at any time by running the created puppet file (eg. /etc/puppet/apply)
            put(<<P_APPLY, "#{puppet_location}/apply")
#!/bin/sh
#{facts} puppet apply \\
 --modulepath=#{puppet_d}/modules:#{puppet_d}/vendor/modules \\
 --templatedir=#{puppet_d}/templates \\
 --fileserverconfig=#{puppet_d}/fileserver.conf \\
 #{puppet_d}/manifests/site.pp
P_APPLY
            run "chmod a+x #{puppet_location}/apply"
            run "sudo #{puppet_location}/apply"
          end
          task :install_vagrant do
            preload_exported_puppet_vars
            # For testing under Vagrant/VirtualBox we can also write
            # /etc/puppet/vagrant-apply which runs puppet
            # using files in the /vagrant directory.  On vagrant+virtualbox
            # deployments this is a shared directory which maps onto the
            # host's project checkout area, so puppet tweaks can be made and
            # tested locally without pushing each change to github.
            facts = Puppetize.load_facts(variables)

            puppet_location = fetch(:puppet_install_dir, "/etc/puppet")
            test_d="/vagrant/config/puppet"
            put(<<V_FILESERVER,"/tmp/fileserver.conf")
[files]
  path #{test_d}/files
  allow 127.0.0.1
[root]
  path /vagrant
  allow 127.0.0.1
V_FILESERVER

            put(<<V_APPLY, "#{puppet_location}/vagrant-apply")
#!/bin/sh
#{facts} puppet apply \\
 --modulepath=#{test_d}/modules:#{test_d}/vendor/modules \\
 --templatedir=#{test_d}/templates  \\
 --fileserverconfig=/tmp/fileserver.conf  \\
 #{test_d}/manifests/site.pp
V_APPLY

            run "chmod a+x #{puppet_location}/vagrant-apply"
            run "sudo #{puppet_location}/vagrant-apply"
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Puppetize.load_into(Capistrano::Configuration.instance)
end
