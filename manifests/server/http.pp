class nagios::server::http (
  http_username,
  http_password,
){

  include nagios::params

  if ! $http_username {
    fail("If http is enabled, a http_username is required.")
  }
  if ! $http_password {
    fail("If http is enabled, a http_password is required.")
  }

  case $http_encryption {
    "md5":   { $http_encryption_flag = "-m" }
    "sha":   { $http_encryption_flag = "-s" }
    "crypt": { $http_encryption_flag = "-d" }
    default: { $http_encryption_flag = "-m" }
  }

  file { $nagios::params::cgi_config_file:
    ensure  => "present",
    content => template("nagios/cgi.cfg"),
    owner   => "root",
    group   => "root",
    mode    => "0644",
    require => [
      Package["nagios-server"],
    ],
  }

  # Create Apache htpasswd file

  exec { "remove-nagios-server-htpasswd-file":
    # Regenerate the file each time so the password always matches the
    # passed Puppet param
    path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    onlyif  => "test -f ${nagios::params::htpasswd_path}",
    command => "rm ${nagios::params::htpasswd_path}",
    require => [
      Package["nagios-server"],
    ],
  }

  exec { "create-nagios-server-htpasswd-file":
    path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "htpasswd -b -c ${http_encryption_flag} ${nagios::params::htpasswd_path} \"${http_username}\" \"${http_password}\"",
    require => [
      Exec["remove-nagios-server-htpasswd-file"],
    ],
  }
}

