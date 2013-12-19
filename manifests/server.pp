class nagios::server (
  $include_nrpe             = true,
  $include_nsca             = false,
  $include_check_mk         = false,
  $http                     = true,
  $http_username            = 'nagiosadmin',
  $http_password            = 'nagiosadmin',
  $http_encryption          = 'md5',
  $enable_external_commands = false,
  $remove_base_configs      = false,
  $remove_example_configs   = true,
){

  include nagios::params
  include nagios::plugins

  package { 'nagios-server':
    name   => $nagios::params::server_packages,
    ensure => 'present',
  }

  # Config files included in Nagios packages

  if $remove_base_configs {
    # The Nagios packages on each system include base files. These are meant
    # to be generic building blocks. It is recommended to keep these files and
    # build on top of them in Puppet.
    file { "${nagios::params::etc_dir}/commands.cfg":                     ensure => 'absent', }
    file { "${nagios::params::conf_dir}/contacts_nagios2.cfg":            ensure => 'absent', }
    file { "${nagios::params::conf_dir}/generic-host_nagios2.cfg":        ensure => 'absent', }
    file { "${nagios::params::conf_dir}/generic-service_nagios2.cfg":     ensure => 'absent', }
    file { "${nagios::params::conf_dir}/timeperiods_nagios2.cfg":         ensure => 'absent', }
    file { "${nagios::params::conf_dir}/check_mk/check_mk_templates.cfg": ensure => 'absent', }
    file { "${nagios::params::objects_dir}/commands.cfg":                 ensure => 'absent', }
    file { "${nagios::params::objects_dir}/contacts.cfg":                 ensure => 'absent', }
    file { "${nagios::params::objects_dir}/printer.cfg":                  ensure => 'absent', }
    file { "${nagios::params::objects_dir}/switch.cfg":                   ensure => 'absent', }
    file { "${nagios::params::objects_dir}/templates.cfg":                ensure => 'absent', }
    file { "${nagios::params::objects_dir}/timeperiods.cfg":              ensure => 'absent', }
    file { "${nagios::params::objects_dir}/windows.cfg":                  ensure => 'absent', }
  }

  if $remove_example_configs {
    # The Nagios packages on each system include example files. These are meant
    # to be overwritten by the user. It is recommended to purge these files and
    # manage nagios resources through puppet.
    file { "${nagios::params::conf_dir}/extinfo_nagios2.cfg":    ensure => 'absent', }
    file { "${nagios::params::conf_dir}/hostgroups_nagios2.cfg": ensure => 'absent', }
    file { "${nagios::params::conf_dir}/localhost_nagios2.cfg":  ensure => 'absent', }
    file { "${nagios::params::conf_dir}/services_nagios2.cfg":   ensure => 'absent', }
    file { "${nagios::params::objects_dir}/localhost.cfg":       ensure => 'absent', }
  }

  # Nagios config

  $plugins_dir = $nagios::params::plugins_dir
  $objects_dir = $nagios::params::objects_dir
  $conf_dir    = $nagios::params::conf_dir
  $external_commands = $enable_external_commands ? {
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

  # Monitoring packages, NRPE, NSCA and Check-MK

  if $include_nrpe {
    include nagios::plugins
  }

  package { 'nagios-nsca-server':
    name    => $nagios::params::nsca_server_packages,
    ensure  => $include_nsca ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
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

  package { 'nagios-check-mk-server':
    name    => $nagios::params::check_mk_server_packages,
    ensure  => $include_check_mk ? { false => 'absent', default => 'present' },
    require => Package['nagios-server'],
    notify  => Service['nagios-server'],
  }

  # Manage Apache HTTP server

  if $http {
    class { 'nagios::server::http':
        http_username => $http_username,
        http_password => $http_password,
    }
  }

  # Fix duplicate host bug

  # Modifies the local Puppet files to apply the patch that was merged into
  # Puppet > 3.3.0. It's a hack, but a smart one. Using puppet to patch puppet.
  # Thanks to Brian Menges for the idea and the solution.
  #
  # http://projects.puppetlabs.com/issues/17871#note-12

  exec { 'projects-puppetlabs-com-issues-17871':
    command => 'sed -i "s/^        @parameters\[pname\] = \*args/        @parameters[pname], = *args/" base.rb',
    onlyif  => 'test -f base.rb && grep -q "^        @parameters\[pname\] = \*args" base.rb',
    cwd     => '/usr/lib/ruby/vendor_ruby/puppet/external/nagios/',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    user    => 'root',
    group   => 'root',
    require => Package['nagios-server'],
    notify  => Exec['clean-config-files'],
  }

  # Fix duplicate nagios resources bug

  # The first time Puppet is run collected Nagios resources are placed into
  # their respective Nagios config files. On the second Puppet run the same
  # duplicate entries are placed into the config files. This causes the
  # Nagios config check to fail, and Nagios service will not start.
  # 
  # The bug is known and nearly two years old, but right now the only fix
  # is to clear all the files and rebuild them on each puppet run. Far from
  # ideal, but it's better than a nonfunctioning Nagios service.
  #
  # http://projects.puppetlabs.com/issues/11921

  exec { 'clean-config-files':
    command => "find ${nagios::params::conf_dir} -type f -name \"nagios_*cfg\" | xargs rm",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    user    => 'root',
    group   => 'root',
    require => Package['nagios-server'],
  }

  # Commands

  file { "${nagios::params::conf_dir}/nagios_command.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Exec['clean-config-files'],
  }

  Nagios_command <| |> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => File["${nagios::params::conf_dir}/nagios_command.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_command <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_command.cfg",
    require => File["${nagios::params::conf_dir}/nagios_command.cfg"],
    notify  => Service['nagios-server'],
  }

  # Contacts

  file { "${nagios::params::conf_dir}/nagios_contact.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Exec['clean-config-files'],
  }

  Nagios_contact <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_contact <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contact.cfg",
    require => File["${nagios::params::conf_dir}/nagios_contact.cfg"],
    notify  => Service['nagios-server'],
  }


  # Contact Groups

  file { "${nagios::params::conf_dir}/nagios_contactgroup.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Exec['clean-config-files'],
  }

  Nagios_contactgroup <| |> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_contactgroup <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_contactgroup.cfg",
    require => File["${nagios::params::conf_dir}/nagios_contactgroup.cfg"],
    notify  => Service['nagios-server'],
  }

  # Hosts

  file { "${nagios::params::conf_dir}/nagios_host.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Exec['clean-config-files'],
  }

  Nagios_host <| |> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => File["${nagios::params::conf_dir}/nagios_host.cfg"],
    notify  => Service['nagios-server'],
  }

  Nagios_host <<| |>> {
    target  => "${nagios::params::conf_dir}/nagios_host.cfg",
    require => File["${nagios::params::conf_dir}/nagios_host.cfg"],
    notify  => Service['nagios-server'],
  }

  # Host Dependencies

  file { "${nagios::params::conf_dir}/nagios_hostdependency.cfg":
    ensure  => 'present',
    mode    => $nagios::params::config_file_mode,
    owner   => 'root',
    group   => 'root',
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
    require => Exec['clean-config-files'],
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
