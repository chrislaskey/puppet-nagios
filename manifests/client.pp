class nagios::client (
  $allowed_hosts,            # Accepts either a string or array of values
  $include_nrpe     = true,
  $include_nsca     = false,
  $include_check_mk = false,
  $nrpe_allow_args  = false,
){

  include nagios::params
  include nagios::plugins

  # Variables

  if is_array($allowed_hosts) {
    $allowed_hosts_string = join($allowed_hosts, ',')
  } elsif is_string($allowed_hosts) {
    $allowed_hosts_string = $allowed_hosts
  } else {
    fail('The "allowed_hosts" parameter must either be a string or an array')
  }

  $dont_blame_nrpe = $nrpe_allow_args ? { false => '0', default => '1' } 
  $nrpe_config_dir = $nagios::params::nrpe_config_dir

  # NRPE

  # The client installs the nrpe package and runs the nrpe server.
  # The Nagios server only installs the nrpe package and runs `check_nrpe` to
  # get from the client.

  if $include_nrpe {
    include nagios::plugins
  }

  package { 'nagios-nrpe-server':
    name    => $nagios::params::nrpe_server_packages,
    ensure  => $include_nrpe ? { false => 'absent', default => 'present' },
  }

  file { 'nagios-nrpe-config':
    ensure  => $include_nrpe ? { false => 'absent', default => 'present' },
    path    => $nagios::params::nrpe_config_file,
    content => template('nagios/nrpe.cfg'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
  }

  service { 'nagios-nrpe-server':
    ensure  => $include_nrpe ? { false => 'stopped', default => 'running' },
    enable  => $include_nrpe ? { false => false, default => true },
    name    => $nagios::params::nrpe_service_name,
    pattern => $nagios::params::nrpe_binary_path,
    require => File['nagios-nrpe-config'],
  }

}
