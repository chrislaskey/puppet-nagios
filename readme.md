About
================================================================================

A puppet module for managing Nagios. Tested on Debian 7.3 and CentOS 6.5.

Module Goals:

- Manage the installation and configuration of Nagios server
- Manage Nagios remote checks via NRPE
- Optionally configure the Nagios server web-interface
- Easy distribution of third-party Nagios plugins

There is also experimental support for `NSCA` and `Check MK`.

## Example

```puppet
# An example /etc/puppet/manifests/nodes.pp file

node "nagios-server" {
  include nagios::server

  # Define a resource either inside the Nagios server node...

  @nagios_host { 'nagios-client-14':
    address => '10.0.0.14',
    use     => 'generic-host',
  }
}

node "nagios-client-01" {

  # ... or define a resource inside the client node.

  @@nagios_host { 'nagios-client-01':
    address => '10.0.0.1',
    use     => 'generic-host',
  }
}
```

Notice all nagios resources can be defined either inside the Nagios server node
using `@virtual` resources or inside the client node using `@@exported`
resources. If using exported resources make sure to have a running `PuppetDB`
instance. All of the built in Puppet `nagios_*` resources are supported.

## Nagios::server

```puppet
class { 'nagios::server':
  include_nrpe                   => true,
  include_nsca                   => false,          # Experimental
  include_check_mk               => false,          # Experimental
  http                           => true,
  http_username                  => 'nagiosadmin',
  http_password                  => 'nagiosadmin',
  http_encryption                => 'md5',
  config_check_external_commands => true,
}
```

By default `nagios::server` will install Nagios server and Nagios plugin meta packages and ensure the service is running.

The class parameters are:

`include_nrpe`  
Defaults to true. Accepts boolean values `true|false`. Installs Nagios NRPE
server and ensures service is running.

`include_nsca`  
Defaults to false. Accepts boolean values `true|false`. Experimental support
for Nagios NSCA style plugins.

`include_check_mk`  
Defaults to false. Accepts boolean values `true|false`. Experimental support
for Nagios Check MK style plugins.

`http`  
Defaults to true. Accepts boolean values `true|false`. Whether to install the
Nagios Admin web-interface. If true, configures Apache web server and generates
login credentials. See `http_username` and `http_password`.

`http_username`  
Defaults to 'nagiosadmin'. Accepts any not null string value. The value is used
for the main web-interface administration account username. Required if `http`
is set to `true`.

`http_password`  
Defaults to 'nagiosadmin'. Accepts any not null string value. The value is used
for the main web-interface administration account password. Required if `http`
is set to `true`.

`http_encryption`  
Defaults to 'md5'. Accepts string values `md5|sha|crypt`. The Nagios admin
web-interface login uses `.htpasswd` files. This sets which encryption scheme
is used to generate the file.

`config_check_external_commands`  
defaults to true. Accepts boolean values `true|false`. Determines whether or
not external commands from the web-interface, like rescheduling a host check,
are accepted.

## Nagios::client

#### Remote checks with NRPE client

```puppet
node "nagios-client-52" {
  # TODO
  # include nagios::client
  # ...
}
```

## Custom plugins

The module supports third-party monitoring plugins downloaded from Nagios
Exchange or elsewhere. Plugin files should be placed in the
`/etc/puppet/modules/nagios/files/plugins` directory on the Puppet Master. Make
sure the executable bit is set.

## Dependences

Requires [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) >=
2.2.0

## For developers

#### Bug fix: Debian Paths

Correct config path in Debian. Uses `/etc/nagios3/` instead of `/etc/nagios/`.

#### Bug fix: Duplicate Resource Definitions

The first time Puppet is run collected Nagios resources are placed into their
respective Nagios config files. On the second Puppet run the same duplicate
entries are placed into the config files. This causes the Nagios config check
to fail, and Nagios service will not start.
   
The bug is known and nearly two years old, but right now the only fix is to
clear all the files and rebuild them on each puppet run. Uses extra resources
but provides a tested and stable work around.
  
See: [Issue 11921](http://projects.puppetlabs.com/issues/11921)

#### Bug fix: Duplicate Host Defintions

A separate bug from the one above can cause the same host to be written
multiple times to the same config file. This bug has been fixed and merged in
Puppet 3.3.0. The module back ports this bugfix to Puppet > 2.7.23.

Thanks to Brian Menges for the idea and the solution.
 
See: [Issue 17871](http://projects.puppetlabs.com/issues/17871#note-12)

License
================================================================================

All code written by me is released under MIT license. See the attached
license.txt file for more information, including commentary on license choice.
