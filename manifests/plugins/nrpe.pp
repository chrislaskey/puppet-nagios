class nagios::plugins::nrpe {

  include nagios::params

  package { 'nagios-nrpe-plugins':
    ensure => $include ? { false => 'absent', default => 'present' },
    name   => $nagios::params::nrpe_plugin_packages,
  }

}
