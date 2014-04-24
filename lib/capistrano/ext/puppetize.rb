require 'capistrano'


module Capistrano
  module Puppetize
    class Config
      def initialize(args)
        # export capistrano variables as Puppet facts so that the
        # site.pp manifest can make decisions on what to install based
        # on its role and environment.  We only export string variables
        # -- not class instances, procs, and other outlandish values
        @facts = args.fetch(:variables).find_all { |k, v| v.is_a?(String) }.
          map {|k, v| "FACTER_cap_#{k}=#{v.inspect}"
        }
        @puppet_root = args.fetch(:puppet_root)
        @project_root = args.fetch(:project_root)
      end

      def fileserver_conf
        <<FILESERVER
[files]
  path #{@puppet_root}/files
  allow 127.0.0.1
[root]
  path #{@project_root}
  allow 127.0.0.1
FILESERVER
      end

      def apply_sh
        <<P_APPLY
#!/bin/sh
#{@facts.join(" ")} puppet apply \\
 --modulepath=#{[@puppet_root + '/modules',
                 @puppet_root + '/vendor/modules'].join(':')} \\
 --templatedir=#{@puppet_root}/templates \\
 --fileserverconfig=#{@puppet_root}/fileserver.conf \\
 #{@puppet_root}/manifests/site.pp
P_APPLY

      end
    end

    def self.load_into(configuration)
      configuration.load do
        before "deploy:finalize_update", "puppet:install"
        namespace :puppet do
          desc "Install and run puppet manifests"
          task :install do
            app_host_name = fetch(:app_host_name) #force this for now
            puppet_conf = Config.new(variables: variables,
                                     puppet_root: fetch(:project_puppet_dir, "#{current_release}/config/puppet"),
                                     project_root: fetch(:current_release))

            install_dir = fetch(:puppet_install_dir, "/etc/puppet")

            put(puppet_conf.fileserver_conf, "#{install_dir}/fileserver.conf")
            put(puppet_conf.apply_sh, "#{install_dir}/apply")

            run "chmod a+x #{install_dir}/apply"
            run "sudo #{install_dir}/apply"
          end
          task :install_vagrant do
            # For testing under Vagrant/VirtualBox we can also write
            # /etc/puppet/vagrant-apply which runs puppet
            # using files in the /vagrant directory.  On vagrant+virtualbox
            # deployments this is a shared directory which maps onto the
            # host's project checkout area, so puppet tweaks can be made and
            # tested locally without pushing each change to github.
            app_host_name = fetch(:app_host_name) #force this for now

            puppet_conf = Config.new(variables: variables,
                                     puppet_root: "/vagrant/config/puppet",
                                     project_root: "/vagrant")

            puppet_location = fetch(:puppet_install_dir, "/etc/puppet")

            put(puppet_conf.fileserver_conf, "/tmp/fileserver.conf")
            v_apply = puppet_conf.apply_sh.sub(/(--fileserverconfig)=(.+)\n/,
                                               '\1=/tmp/fileserver.conf')
            put(v_apply, "#{puppet_location}/vagrant-apply")

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
