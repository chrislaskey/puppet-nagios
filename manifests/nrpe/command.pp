define nagios::nrpe::command (
  $command_name = $title,
  $command,
){

  include nagios::params

  $plugins_dir = $nagios::params::plugins_dir

  file { "nrpe::command::${name}":
    ensure  => 'present',
    path    => "${nagios::params::nrpe_config_dir}/${title}.cfg",
    content => template('nagios/nrpe_command.cfg'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
  }

}
