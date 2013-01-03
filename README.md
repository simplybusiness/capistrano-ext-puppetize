# capistrano-ext-puppetize

A Capistrano extension to run Puppet manifests contained in the application repository before deploying the application.  This means that all third party daemons, configs, services, libraries and other dependencies of an application can be specified by that application.


## Where it fits in the boostrapping picture

It requires that the host(s) deployed onto already has installed Puppet and a version of Ruby capable of running it: at Simply Business we install the CentOS system Ruby and the Puppet RPMs from Puppet Labs in our base image/AMIs

It doesn't need RVM installed beforehand - we usually use it to install RVM and the application-specific Ruby.


## How to use it 

At the top of `Capfile` or `config/deploy.rb` add the line
````
require "capistrano/ext/puppetize"
````
This will define a Capistrano recipe `puppet:install` and hook it to run before `deploy:finalize_update`.  When the recipe runs it will cause the upload and execution of a file `/etc/puppet/apply` which runs Puppet in standalone (masterless) mode with a slew of appropriate parameters and options

* the puppet manifest in `config/puppet/manifests/site.pp` is run

* all string-valued Capistrano variables will be available as facts, with names prefixed `cap_` - for example, `deploy_to` is available as the Puppet fact `cap_deploy_to` 

* a fileserver configuration is created such that `puppet:///files/foo` refers to `config/puppet/files/foo`

* the modulepath is set to find modules in `config/puppet/modules` and 
`config/puppet/vendor/modules`

* the template directory is set to `config/puppet/templates`

The file `/etc/puppet/apply` is a perfectly ordinary shell script which can also be run at other times (e.g. unattended at boot, or from cron) to ensure that the system state is correct without having to do a deploy.


### Living with RVM

1. Remove any/all use of the rvm-capistrano extension, which interferes badly with our desire to run things on RVM-less systems. 

1. If you are using bundler and intend to use RVM, set the `bundle_cmd` setting appropriately (and make sure you're using it instead of hardcoding the string)

````
set :rvm_ruby_string, '1.9.3-p194'
set :bundle_cmd, "rvm #{rvm_ruby_string} do bundle" 
````

1. Likewise for other commands that need to run in the context ot rvm
````
set :unicorn_command, "rvm #{rvm_ruby_string} do bundle exec unicorn_rails"
````
1. A convenient way of installing RVM using Puppet is to use the puppet module at https://github.com/jfryman/puppet-rvm


