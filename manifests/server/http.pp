class nagios::server::http (
  http_username,
  http_password,
  http_encryption,
  http_external_commands,
){

  include nagios::params

  $nagios_path_name = $nagios::params::nagios_path_name

  if ! $http_username {
    fail('If http is enabled, a http_username is required.')
  }
  if ! $http_password {
    fail('If http is enabled, a http_password is required.')
  }

  case $http_encryption {
    'md5':   { $http_encryption_flag = '-m' }
    'sha':   { $http_encryption_flag = '-s' }
    'crypt': { $http_encryption_flag = '-d' }
    default: { $http_encryption_flag = '-m' }
  }

  file { $nagios::params::cgi_config_file:
    ensure  => 'present',
    content => template('nagios/cgi.cfg'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nagios-server'],
  }

  # Create Apache htpasswd file

  exec { 'remove-nagios-server-htpasswd-file':
    # Regenerate the file each time so the password always matches the
    # passed Puppet param
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    onlyif  => "test -f ${nagios::params::htpasswd_path}",
    command => "rm ${nagios::params::htpasswd_path}",
    require => Package['nagios-server'],
  }

  exec { 'create-nagios-server-htpasswd-file':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "htpasswd -b -c ${http_encryption_flag} ${nagios::params::htpasswd_path} \"${http_username}\" \"${http_password}\"",
    require => Exec['remove-nagios-server-htpasswd-file'],
  }

  # Fix permissions for external commands file

  if $http_external_commands {
    exec { 'add-nagios-group-to-apache-user':
      command => "usermod -aG nagios ${nagios::params::http_user}",
      unless  => "groups ${nagios::params::http_user} | grep nagios",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      user    => 'root',
      group   => 'root',
      require => Package['nagios-server'],
    }

    if $::osfamily == 'Debian' {
      # Fix for a long existing bug in Debian:
      # http://sharadchhetri.com/2013/06/05/error-could-not-stat-command-file-varlibnagios3rwnagios-cmd/
      exec { 'fix-bug-in-apache-pipe':
        command     => '/etc/init.d/nagios3 stop && dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw && dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3 && /etc/init.d/nagios3 start',
        unless      => 'dpkg-statoverride --list | grep -e "/var/lib/nagios3/rw" -e "/var/lib/nagios3"',
        path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        user        => 'root',
        group       => 'root',
        require     => Package['nagios-server'],
      }
    }
  }
}
