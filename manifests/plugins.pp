class nagios::plugins {

  include nagios::params

  # Plugins from repositories

  package { 'nagios-plugins':
    name => $nagios::params::plugin_packages,
  }

  package { 'nagios-plugins-snmp':
    name => $nagios::params::plugin_packages_snmp,
  }

  # Third-party plugins

  file { 'nagios-additional-plugin-files':
    path    => $nagios::params::plugins_dir,
    source  => 'puppet:///modules/nagios/plugins',
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => false,
    force   => false,
    require => Package['nagios-plugins'],
  }

}
