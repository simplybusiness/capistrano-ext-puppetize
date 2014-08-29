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
        @module_paths = args.fetch(:module_paths)
        @install_dir = args.fetch(:install_dir, "/etc/puppet")
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

      def all_module_paths
        @module_paths +
          [@puppet_root + '/modules',
           @puppet_root + '/vendor/modules']
      end

      def apply_sh
        <<P_APPLY
#!/bin/sh
#{@facts.join(" ")} puppet apply \\
 --modulepath=#{all_module_paths.join(':')} \\
 --templatedir=#{@puppet_root}/templates \\
 --fileserverconfig=#{@puppet_root}/fileserver.conf \\
 #{@puppet_root}/manifests/site.pp
P_APPLY

      end
    end
  end
end
