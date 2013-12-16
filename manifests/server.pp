class nagios::server (
  $include_nrpe = true,
  $include_nsca = true,
  $include_check_mk = true,
  $config_check_external_commands = false,
  $http = true,
  $http_username = undef,
  $http_password = undef,
  $http_encryption = 'md5',
){

  include nagios::params
  include nagios::plugins

  package { 'nagios-server':
    name   => $nagios::params::server_packages,
    ensure => 'present',
  }

  package { 'nagios-nrpe-server':
    name    => $nagios::params::nrpe_server_packages,
    ensure  => $include_nrpe ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  package { 'nagios-nsca-server':
    name    => $nagios::params::nsca_server_packages,
    ensure  => $include_nsca ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  package { 'nagios-check-mk-server':
    name    => $nagios::params::check_mk_server_packages,
    ensure  => $include_check_mk ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Remove example configuration files that might throw errors in production.
  # Keep helpful building blocks like timeperiod, generic-service, etc.

  file { "${nagios::params::conf_dir}/extinfo_nagios2.cfg":    ensure => 'absent', }
  file { "${nagios::params::conf_dir}/hostgroups_nagios2.cfg": ensure => 'absent', }
  file { "${nagios::params::conf_dir}/localhost_nagios2.cfg":  ensure => 'absent', }
  file { "${nagios::params::conf_dir}/services_nagios2.cfg":   ensure => 'absent', }
  file { "${nagios::params::objects_dir}/localhost.cfg":       ensure => 'absent', }

  # Nagios config

  $plugins_dir = $nagios::params::plugins_dir
  $objects_dir = $nagios::params::objects_dir
  $conf_dir    = $nagios::params::conf_dir
  $check_external_commands = $config_check_external_commands ? {
    true    => '1',
    default => '0',
  }

  file { $nagios::params::config_file:
    ensure  => 'present',
    content => template($nagios::params::config_file_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Nagios service

  service { 'nagios-server':
    enable    => true,
    ensure    => running,
    name      => $nagios::params::service_name,
    pattern   => $nagios::params::binary_path,
    require   => Package['nagios-server'],
    subscribe => File [$nagios::params::cgi_config_file],
  }

  service { 'nagios-nrpe-server':
    ensure  => $include_nrpe ? { false => 'stopped', default => 'running' },
    enable  => $include_nrpe ? { false => false, default => true },
    name    => $nagios::params::nrpe_service_name,
    pattern => $nagios::params::nrpe_binary_path,
    require => Package['nagios-nrpe-server'],
  }

  service { 'nagios-nsca-server':
    # NOTE: The init script for the NSCA server on Debian 7 is buggy.
    # The command `invoke-rc.d nsca start` can fail but still return 0.
    # Puppet does not seem to know how to handle this, and will not output
    # anything - neither a NOTICE of success or a ERROR.
    ensure  => $include_nsca ? { false => 'stopped', default => 'running' },
    enable  => $include_nsca ? { false => false, default => true },
    name    => $nagios::params::nsca_service_name,
    pattern => $nagios::params::nsca_binary_path,
    require => Package['nagios-nsca-server'],
  }

  # Manage Apache HTTP server

  if $http {
    class { 'nagios::server::http':
        http_username => $http_username,
        http_password => $http_password,
    }
  }

  # Commands

  file { "${nagios::params::conf_dir}/nagios_command.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_command <| |> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_command.cfg"],
  }

  Nagios_command <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_command.cfg"],
  }

  # Contacts

  file { "${nagios::params::conf_dir}/nagios_contact.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_contact <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
  }

  Nagios_contact <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
  }


  # Contact Groups

  file { "${nagios::params::conf_dir}/nagios_contactgroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_contactgroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
  }

  Nagios_contactgroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
  }

  # Hosts

  file { "${nagios::params::conf_dir}/nagios_host.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_host <| |> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_host.cfg"],
  }

  Nagios_host <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_host.cfg"],
  }

  # Host Dependencies

  file { "${nagios::params::conf_dir}/nagios_hostdependency.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_hostdependency <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostdependency.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostdependency.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_hostdependency <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostdependency.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostdependency.cfg"],
    notify  => Service['nagios-server'],
  }

  # Host Escalations

  file { "${nagios::params::conf_dir}/nagios_hostescalation.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_hostescalation <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostescalation.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostescalation.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_hostescalation <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostescalation.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostescalation.cfg"],
    notify  => Service['nagios-server'],
  }

  # Host Ext Infos

  file { "${nagios::params::conf_dir}/nagios_hostextinfo.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_hostextinfo <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostextinfo.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostextinfo.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_hostextinfo <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostextinfo.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostextinfo.cfg"],
    notify  => Service['nagios-server'],
  }

  # Host Groups

  file { "${nagios::params::conf_dir}/nagios_hostgroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_hostgroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostgroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostgroup.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_hostgroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostgroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_hostgroup.cfg"],
    notify  => Service['nagios-server'],
  }

  # Services

  file { "${nagios::params::conf_dir}/nagios_service.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_service <| |> {
    target  => "${nagios::params::conf_dir}/nagios_service.cfg",
    require => File["${nagios::params::conf_dir}/nagios_service.cfg"],
    notify  => Service['nagios-server'],
  }
  
  Nagios_service <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_service.cfg",
    require => File["${nagios::params::conf_dir}/nagios_service.cfg"],
    notify  => Service['nagios-server'],
  }

  # Service Dependencies

  file { "${nagios::params::conf_dir}/nagios_servicedependency.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_servicedependency <| |> {
    target  => "${nagios::params::conf_dir}/nagios_servicedependency.cfg",
    require => File["${nagios::params::conf_dir}/nagios_servicedependency.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_servicedependency <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_servicedependency.cfg",
    require => File["${nagios::params::conf_dir}/nagios_servicedependency.cfg"],
    notify  => Service['nagios-server'],
  }

  # Service Escalations

  file { "${nagios::params::conf_dir}/nagios_serviceescalation.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_serviceescalation <| |> {
    target  => "${nagios::params::conf_dir}/nagios_serviceescalation.cfg",
    require => File["${nagios::params::conf_dir}/nagios_serviceescalation.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_serviceescalation <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_serviceescalation.cfg",
    require => File["${nagios::params::conf_dir}/nagios_serviceescalation.cfg"],
    notify  => Service['nagios-server'],
  }

  # Service Ext Infos

  file { "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_serviceextinfo <| |> {
    target  => "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg",
    require => File["${nagios::params::conf_dir}/nagios_serviceextinfo.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_serviceextinfo <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg",
    require => File["${nagios::params::conf_dir}/nagios_serviceextinfo.cfg"],
    notify  => Service['nagios-server'],
  }

  # Service Groups

  file { "${nagios::params::conf_dir}/nagios_servicegroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_servicegroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_servicegroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_servicegroup.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_servicegroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_servicegroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_servicegroup.cfg"],
    notify  => Service['nagios-server'],
  }

  # Timeperiods

  file { "${nagios::params::conf_dir}/nagios_timeperiod.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  Nagios_timeperiod <| |> {
    target  => "${nagios::params::conf_dir}/nagios_timeperiod.cfg",
    require => File["${nagios::params::conf_dir}/nagios_timeperiod.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_timeperiod <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_timeperiod.cfg",
    require => File["${nagios::params::conf_dir}/nagios_timeperiod.cfg"],
    notify  => Service['nagios-server'],
  }
}
