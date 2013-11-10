About
================================================================================

The `nagios` module handles basic installation of Nagios clients and servers
for Debian (stable) and RedHat (experimental) family distributions.

nagios::client
--------------

```puppet
class { "nagios::client":
	allowed_hosts => [1.1.1.1, 1.1.1.2],
}
```

### Parameters

##### `allowed_hosts`

Parameter accepts either a single string value or an array of string values.

Default value is `127.0.0.1`.   

nagios::server
--------------

```puppet
class { "nagios::server":
	http => true,
	http_username => "nagiosadmin",
	http_password => "nagiosadmin",
	http_encryption => "md5",
){
```

### Parameters

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
