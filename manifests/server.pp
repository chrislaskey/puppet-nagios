class nagios::server (
  $include_nrpe = true,
  $include_nsca = true,
  $include_check_mk = true,
  $http = true,
  $http_username = undef,
  $http_password = undef,
  $http_encryption = 'md5',
){

  include nagios::params

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

  package { 'nagios-check_mk-server':
    name    => $nagios::params::check_mk_server_packages,
    ensure  => $include_check_mk ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Remove example configuration files that might throw errors in production.
  # Keep helpful building blocks like timeperiod, generic-service, etc.

  # TODO: Check file names in RedHat

  file { "${nagios::params::conf_dir}/extinfo_nagios2.cfg":    ensure => 'absent', }
  file { "${nagios::params::conf_dir}/hostgroups_nagios2.cfg": ensure => 'absent', }
  file { "${nagios::params::conf_dir}/localhost_nagios2.cfg":  ensure => 'absent', }
  file { "${nagios::params::conf_dir}/services_nagios2.cfg":   ensure => 'absent', }

  # Nagios service

  service { 'nagios-server':
    enable  => true,
    ensure  => running,
    name    => $nagios::params::service_name,
    pattern => $nagios::params::binary_path,
    require => [
      Package['nagios-server'],
    ],
    subscribe => [
      File [$nagios::params::cgi_config_file],
    ],
  }

  # Manage Apache HTTP server

  if $http {
    class { 'nagios::server::http':
        http_username => $http_username,
        http_password => $http_password,
    }
  }

  # Commands

  Nagios_command <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_command.cfg"],
  }

  Nagios_command <| |> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_command.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_command.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Contacts

  Nagios_contact <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
  }

  Nagios_contact <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_contact.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Contact Groups

  Nagios_contactgroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
  }

  Nagios_contactgroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_contactgroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Hosts

  Nagios_host <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_host.cfg"],
  }

  Nagios_host <| |> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_host.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_host.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Host Dependencies

  Nagios_hostdependency <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostdependency.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostdependency.cfg"],
  }

  Nagios_hostdependency <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostdependency.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostdependency.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_hostdependency.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Host Escalations

  Nagios_hostescalation <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostescalation.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostescalation.cfg"],
  }

  Nagios_hostescalation <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostescalation.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostescalation.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_hostescalation.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Host Ext Infos

  Nagios_hostextinfo <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostextinfo.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostextinfo.cfg"],
  }

  Nagios_hostextinfo <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostextinfo.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostextinfo.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_hostextinfo.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Host Groups

  Nagios_hostgroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_hostgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostgroup.cfg"],
  }

  Nagios_hostgroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_hostgroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_hostgroup.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_hostgroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Services
  
  Nagios_service <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_service.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_service.cfg"],
  }

  Nagios_service <| |> {
    target  => "${nagios::params::conf_dir}/nagios_service.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_service.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_service.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Service Dependencies

  Nagios_servicedependency <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_servicedependency.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_servicedependency.cfg"],
  }

  Nagios_servicedependency <| |> {
    target  => "${nagios::params::conf_dir}/nagios_servicedependency.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_servicedependency.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_servicedependency.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Service Escalations

  Nagios_serviceescalation <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_serviceescalation.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_serviceescalation.cfg"],
  }

  Nagios_serviceescalation <| |> {
    target  => "${nagios::params::conf_dir}/nagios_serviceescalation.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_serviceescalation.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_serviceescalation.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Service Ext Infos

  Nagios_serviceextinfo <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_serviceextinfo.cfg"],
  }

  Nagios_serviceextinfo <| |> {
    target  => "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_serviceextinfo.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_serviceextinfo.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Service Groups

  Nagios_servicegroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_servicegroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_servicegroup.cfg"],
  }

  Nagios_servicegroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_servicegroup.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_servicegroup.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_servicegroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Timeperiods

  Nagios_timeperiod <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_timeperiod.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_timeperiod.cfg"],
  }

  Nagios_timeperiod <| |> {
    target  => "${nagios::params::conf_dir}/nagios_timeperiod.cfg",
    require => Package['nagios-server'],
    notify  => File["${nagios::params::conf_dir}/nagios_timeperiod.cfg"],
  }

  file { "${nagios::params::conf_dir}/nagios_timeperiod.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }
}
