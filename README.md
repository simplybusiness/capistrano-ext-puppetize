# capistrano-ext-puppetize

A Capistrano extension to run Puppet manifests contained in the application repository before deploying the application.  This means that all third party daemons, configs, services, libraries and other dependencies of an application can be specified by that application.


## Where it fits in the bootstrapping picture

It requires that the host(s) deployed onto already has installed Puppet and a version of Ruby capable of running it: at Simply Business we install the CentOS system Ruby and the Puppet RPMs from Puppet Labs in our base image/AMIs

It doesn't need RVM installed beforehand - we don't use RVM (or anything like it) on our production machines, but when we did, we would usually use this module to install RVM and the application-specific Ruby.


## How to use it 

At the top of `Capfile` or `config/deploy.rb` add the line
````
require "capistrano/ext/puppetize"
````
This will define a Capistrano recipe `puppet:install` and hook it to run before `deploy:finalize_update`.  

### What it does

By default, when the recipe runs it will cause the creation and execution of a file `/etc/puppet/apply` on the target machine which runs Puppet in standalone (masterless) mode with a slew of appropriate parameters and options:

* the puppet manifest in `config/puppet/manifests/site.pp` is run

* all string-valued Capistrano configuration variables will be available as facts, with names prefixed `cap_` - for example, the Capistrano `:deploy_to` setting is available as the Puppet fact `cap_deploy_to`.  Note that this does not cause the evaluation of variables that have not yet been evaluated (otherwise you tend to get annoying password prompts) 

* a fileserver configuration is created such that `puppet:///files/foo` refers to `config/puppet/files/foo` and `puppet:///root/foo` refers to `foo` in the top directory of the project

* the modulepath is set to find modules in `config/puppet/modules` and 
`config/puppet/vendor/modules`.  If you have other places you
keep modules, add them to the Capistrano setting `puppet_module_paths`

* the template directory is set to `config/puppet/templates`

The file `/etc/puppet/apply` is a perfectly ordinary shell script which can also be run at other times (e.g. unattended at boot, or from cron) to ensure that the system state is correct without having to do a deploy.

NOTE: These paths will be different if you have specified custom parameters in the `deploy.rb` file (See below)

### Customising parameters

You can specify options for your project but adding the following to the deploy.rb:
```ruby
set :project_puppet_dir, "foo/bar/"
#Default location if not set: #{current_release}/config/puppet/

To specify where to put the puppet executable `apply` file
set :puppet_install_dir, "/opt/scripts/puppet"
#Default location if not set: /etc/puppet/
```

### Living with RVM

1. Remove any/all use of the rvm-capistrano extension, which interferes badly with our desire to run things on RVM-less systems. 

1. If you are using bundler and intend to use RVM, set the `bundle_cmd` setting appropriately (and make sure you're using it instead of hardcoding the string)

````
set :rvm_ruby_string, '1.9.3-p194'
set :bundle_cmd, "rvm #{rvm_ruby_string} do bundle" 
# ...
run "cd #{current_path} && #{try_sudo} #{bundle_cmd} exec unicorn -c #{current_path}/config/unicorn.xhr.rb -E #{rails_env} -D"
````

1. Likewise for other commands that need to run in the context of rvm
````
set :whenever_command, "#{fetch(:bundle_cmd)} exec whenever"
````
1. A convenient way of installing RVM using Puppet is to use the puppet module at https://github.com/jfryman/puppet-rvm


Side note: there is an Internet rule that any request for advice on how to do X can be fulfilled by the simple admonition "Don't do X", and that this reply must be accepted regardless of the value of X.  Although unconvinced that this is, in general, How Things Should Be, when X is "RVM on production systems" a strong case could be made for its observance.  Really, why are you deploying more than one version of Ruby to the same production system? 
