About
================================================================================

A puppet module for managing Nagios. The module goals include:

- Manage the installation and configuration of Nagios server
- Manage Nagios remote client checks with NRPE
- Configure the Nagios server web-interface if requested
- Easy distribution of third-party Nagios plugins

There is also experimental support for `NSCA` and `Check MK`.

Tested on Debian 7.3 and CentOS 6.5.

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

See below for a more advanced example.

## nagios::server

```puppet
class { 'nagios::server':
  include_nrpe             => true,
  include_nsca             => false,          # Experimental
  include_check_mk         => false,          # Experimental
  http                     => true,
  http_username            => 'nagiosadmin',
  http_password            => 'nagiosadmin',
  http_encryption          => 'md5',
  enable_external_commands => false,
}
```

By default `nagios::server` will install Nagios server and Nagios plugin meta
packages and ensure the service is running.

The `nagios::server` class parameters are:

`include_nrpe`  
Defaults to true. Accepts boolean values `true|false`. Installs Nagios NRPE
server and ensures service is running.

`include_nsca`  
Defaults to false. Accepts boolean values `true|false`. Experimental support
for passive checks with NSCA. Installs NSCA server.

`include_check_mk`  
Defaults to false. Accepts boolean values `true|false`. Experimental support
for Nagios checks with Check MK.

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

`enable_external_commands`  
Defaults to false. Accepts boolean values `true|false`. Determines whether or
not external commands from the web-interface, like rescheduling a host check,
are accepted.

## nagios::client

```puppet
class { 'nagios::client':
  allowed_hosts    => '127.0.0.1', # Required, defaults to no value
  include_nrpe     => true,
  include_nsca     => false,
  include_check_mk => false,
  nrpe_allow_args  => false,
}
```

The Nagios server can monitor remote clients without anything installed on the
client. This class is optional. It enables more detailed checks on the client
through active checks with `NRPE`, passive checks with `NSCA` or data rich
checks with `Check MK`.

Support for `NRPE` is complete. Support for `NSCA` and `Check MK` is
experimental.

The `nagios::client` parameters are:

`allowed_hosts`  
Required. Accepts either a string value or an array of strings. It is
recommened to include `127.0.0.1` along with the Nagios server IP.

`include_nrpe`  
Defaults to true. Accepts boolean values `true|false`. Installs Nagios NRPE
client and ensures service is running. 

`include_nsca`  
Defaults to false. Accepts boolean values `true|false`. Experimental support
for passive checks with NSCA. Installs NSCA client.

`include_check_mk`  
Defaults to false. Accepts boolean values `true|false`.  Experimental support
for Nagios checks with Check MK.

`nrpe_allow_args`  
Defaults to false. Accepts boolean values `true|false`. Determines whether or
not remote `check_nrpe` calls can send custom arguments like warning levels,
etc.

#### Configuring host for Nagios NRPE client

NRPE requires `port 5666` to be open on the client machine. Otherwise
`check_nrpe` commands will return the error "connection refused or timed out".

Most Debian distributions do not include DENY firewall rules out of the box,
so configuration may not be necessary.

On the other hand RedHat distributions do include firewall rules out of the
box. Opening the NRPE port can be accomplished by adding a new `iptables` rule.
For example in `/etc/sysconfig/iptables` under `:OUTPUT ACCEPT`:

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 5666 -j ACCEPT

Would open the default NRPE port. For Puppet based firewall management see the
excellent
[puppetlabs/firewall](https://forge.puppetlabs.com/puppetlabs/firewall) module.

## nagios::nrpe::command

```puppet
nagios::nrpe::command { 'command_name':
  command => '', # Required, defaults to no value
}
```

NRPE requires commands to be defined on the client before they can be called by
the Nagios server. This command creates NRPE command definitions and stores
them in the `nrpe.d` directory.

The `nagios::nrpe::command` parameters are:

`command_name`  
Defaults to `$title`. Accepts a string value. The name of the remote
check.

`command`  
Defaults to true. Accepts boolean values `true|false`. The plugin name and any
arguments it may take. Do not include plugin path, this is automatically
prepended to the command.

#### nagios::nrpe::command example

The following puppet node definition creates two new `nrpe.d` files:

```puppet
node "client-node" {
  nagios::nrpe::command { 'check_load':
    command => 'check_load -w 30,20,10 -c 50,40,30',
  }

  nagios::nrpe::command { 'check_all_disks':
    command => 'check_disk -w $ARG1$ -c $ARG2$ -e',
  }
}
```

The first file created is `check_load.cfg` and contains:

    command[check_load]=/usr/lib/nagios/plugins/check_load -w 30,20,10 -c 50,40,30

Notice the argument values are hardwired. The second file created is
`check_all_disks.cfg`:

    command[check_all_disks]=/usr/lib/nagios/plugins/check_disk -w $ARG1$ -c $ARG2$ -e

The second remote command defines dynamic arguments. The Nagios server can now
send dynamic values for the warning `-w` and critical `-c` threshold arguments.

    # On Nagios server
    $  ./check_nrpe -H client-node -c check_all_disks -a 80% 90%

Note passing dynamic arguments requires enabling external commands. This can be
done by setting `enable_external_commands => true` in the `nagios::client`
definition.

## Custom plugins

The module supports third-party monitoring plugins downloaded from Nagios
Exchange or elsewhere. Plugin files should be placed in the
`/etc/puppet/modules/nagios/files/plugins` directory on the Puppet Master. Make
sure the executable bit is set.

## A complete monitoring example

```
# TODO
```

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
