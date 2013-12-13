class nagios::server (
  http = true,
  http_username = undef,
  http_password = undef,
  http_encryption = "md5",
){

  include nagios::params

  package { "nagios-server":
    name => [
      "nagios3",
      "nagios-plugins",
      "nagios-nrpe-plugin",
    ],
    ensure => "present",
  }

  # Nagios config files

  file { $nagios_cgi_config_file:
    ensure => "present",
    content => template("nagios/cgi.cfg"),
    owner => "root",
    group => "root",
    mode => "0644",
    require => [
      Package["nagios-server"],
    ],
  }

  # Remove example configuration files
  # TODO: Check file names in RedHat

  file { "${nagios_conf_dir}/extinfo_nagios2.cfg":    ensure => 'absent', }
  file { "${nagios_conf_dir}/hostgroups_nagios2.cfg": ensure => 'absent', }
  file { "${nagios_conf_dir}/localhost_nagios2.cfg":  ensure => 'absent', }
  file { "${nagios_conf_dir}/services_nagios2.cfg":   ensure => 'absent', }

  # Nagios service

  service { "nagios-server":
    enable => true,
    ensure => running,
    name => $nagios_service_name,
    pattern => $nagios_binary_path,
    require => [
      Package["nagios-server"],
    ],
    subscribe => [
      File [$nagios_cgi_config_file],
    ],
  }

  # Create Apache htpasswd file

  exec { "remove-nagios-server-htpasswd-file":
    # Regenerate the file each time so the password always matches the
    # passed Puppet param
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    onlyif => "test -f ${http_htpasswd_path}",
    command => "rm ${http_htpasswd_path}",
    require => [
      Package["nagios-server"],
    ],
  }

  exec { "create-nagios-server-htpasswd-file":
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "htpasswd -b -c ${http_encryption_flag} ${http_htpasswd_path} \"${http_username}\" \"${http_password}\"",
    require => [
      Exec["remove-nagios-server-htpasswd-file"],
    ],
  }

  # Collect puppet exported resources

  Nagios_command <<| |>> {
    target => "${nagios_conf_dir}/nagios_command.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_command.cfg"],
  }

  Nagios_command <| |> {
    target => "${nagios_conf_dir}/nagios_command.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_command.cfg"],
  }

  file { "${nagios_conf_dir}/nagios_command.cfg":
    # On Debian permissions need to be 0644 not default 0600
    ensure => "present",
    mode => $nagios_config_file_mode,
    owner => "root",
    group => "root",
    require => Package["nagios-server"],
    notify => Service["nagios-server"],
  }

  Nagios_host <<| |>> {
    target => "${nagios_conf_dir}/nagios_host.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_host.cfg"],
  }

  Nagios_host <| |> {
    target => "${nagios_conf_dir}/nagios_host.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_host.cfg"],
  }

  file { "${nagios_conf_dir}/nagios_host.cfg":
    # On Debian permissions need to be 0644 not default 0600
    ensure => "present",
    mode => $nagios_config_file_mode,
    owner => "root",
    group => "root",
    require => Package["nagios-server"],
    notify => Service["nagios-server"],
  }

  Nagios_service <<| |>> {
    target => "${nagios_conf_dir}/nagios_service.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_service.cfg"],
  }

  Nagios_service <| |> {
    target => "${nagios_conf_dir}/nagios_service.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_service.cfg"],
  }

  file { "${nagios_conf_dir}/nagios_service.cfg":
    # On Debian permissions need to be 0644 not default 0600
    ensure => "present",
    mode => $nagios_config_file_mode,
    owner => "root",
    group => "root",
    require => Package["nagios-server"],
    notify => Service["nagios-server"],
  }

  Nagios_servicegroup <<| |>> {
    target => "${nagios_conf_dir}/nagios_servicegroup.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_servicegroup.cfg"],
  }

  Nagios_servicegroup <| |> {
    target => "${nagios_conf_dir}/nagios_servicegroup.cfg",
    require => Package["nagios-server"],
    notify => File["${nagios_conf_dir}/nagios_servicegroup.cfg"],
  }

  file { "${nagios_conf_dir}/nagios_servicegroup.cfg":
    # On Debian permissions need to be 0644 not default 0600
    ensure => "present",
    mode => $nagios_config_file_mode,
    owner => "root",
    group => "root",
    require => Package["nagios-server"],
    notify => Service["nagios-server"],
  }

}
