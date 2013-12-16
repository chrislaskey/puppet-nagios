class nagios::plugins {

  include nagios::params

  # Plugins from repositories

  package { 'nagios-plugins':
    name => $nagios::params::plugin_packages,
  }

  # Third-party plugins

  file { 'nagios-additional-plugin-files':
    path    => $nagios::params::plugins_dir,
    source  => 'puppet:///nagios/plugins',
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
