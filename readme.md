About
================================================================================

A puppet module for managing Nagios. Tested on Debian 7.3 and CentOS 6.5.

Module Goals:

- Manage the installation and configuration of Nagios server
- Manage Nagios remote checks via NRPE
- Set up the Nagios server web-interface
- Allow custom Nagios plugins

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
Nagios Admin web-interface. See `http_username` and `http_password`.

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

## For developers

#### Bug fix: Debian Paths

#### Bug fix: Duplicate Resource Definitions

#### Bug fix: Duplicate Host Defintions


Bug fixes
---------

Correct config path in Debian. Uses `/etc/nagios3/` instead of `/etc/nagios/`.

Backport duplicate host bug to work in Puppet < 3.3.0.

Provide a tested and stable work around for a known duplicate resources bug that can prevent Nagios server from starting.

Puppet supports native resource types in Puppet. Exporting

The module includes bug fixes for Nagios resources.

There are two known bugs in Puppet

The `nagios` module handles basic installation of Nagios clients and servers
for Debian (stable) and RedHat (experimental) family distributions.

Example
-------

```puppet
# /etc/puppet/manifests/nodes.pp

node "nagios-server" {
	class { "nagios::server":
		http_username => "nagiosadmin",
		http_password => "nagiosadmin",
	}
}

node "nagios-client1" {
	class { "nagios::client":
		allowed_hosts => ["1.1.1.1", "1.1.1.2"],
	}

	# Use any of the standard puppet exported resources

	@@nagios_host { $::fqdn:
		ensure => present,
		alias => $::hostname,
		address => $::ipaddress,
		use => "generic-host",
	}
}
```

nagios::client
--------------

```puppet
class { "nagios::client":
	allowed_hosts => "127.0.0.1",
}
```

#### Parameters

##### `allowed_hosts`

Parameter accepts either a single string value or an array of string values.

Default value is `127.0.0.1`.

nagios::server
--------------

```puppet
class { "nagios::server":
	http => true,
	http_username => undef,
	http_password => undef,
	http_encryption => "md5",
){
```

#### Parameters

##### `http`

The module installs the `nagios` meta package which includes the web interface. `http` variable is used to determine if an admin account is made to access the web interface. When `false` no account is made and the web interface will still exist but have no available logins.

Default value is `true`. Parameter accepts either `true` or `false`.

##### `http_username`

The string value for the username for the web interface login.

Default value is `undef`. If `http` parameter is set to `true`, a string value for this parameter must be defined.

##### `http_password`

The string value for the password for the web interface login.

Default value is `undef`. If `http` parameter is set to `true`, a string value for this parameter must be defined.

##### `http_encryption`

This parameter sets the encryption used for the `htpasswd` key generation.

Default value is `md5`. Other parameter options include `sha` and `crypt`.

Dependences
-----------

Requires [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) >=
2.2.1

Todo
----

- Add support for collecting all Nagios related [Puppet resource
types](http://docs.puppetlabs.com/references/latest/type.html#nagios_service-attribute-target).
Currently only supports Nagios_service and Nagios_host.

License
================================================================================

All code written by me is released under MIT license. See the attached
license.txt file for more information, including commentary on license choice.
