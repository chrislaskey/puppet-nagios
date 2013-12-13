class nagios::params () {

## Regular packages

# Debian
# nagios3
# nagios-plugins
# nagios-plugins-snmp

# Redhat
# nagios
# nagios-plugins
# nagios-plugins-all


## NRPE packages

# Debian
# nagios-nrpe-client
# nagios-nrpe-server

# Redhat
# nrpe
# nagios-plugins-nrpe


## NSCA packages

# Debian
# nsca
# nsca-client

# Redhat
# nsca
# nsca-client


## Check MK packages

# Debian
# check-mk-agent
# check-mk-server

# Redhat
# check-mk-agent
# check-mk


  case $::osfamily {
    "Debian": {
#      $packages_server = ['nagios3'],
      $service_name = "nagios3"
      $binary_path = "/usr/sbin/nagios3"
      $htpasswd_path = "/etc/nagios3/htpasswd.users"
      $http_config_path = "/etc/nagios3/apache.conf"
      $conf_dir = "/etc/nagios3/conf.d"
      $config_file_mode = "0644"
      $cgi_config_file = "/etc/nagios3/cgi.cfg"
    }
    "RedHat": {
#      $packages_server = ['nagios'],
      $service_name = "nagios"
      $binary_path = "/usr/sbin/nagios"
      $htpasswd_path = "/etc/nagios/.htpasswd"
      $http_config_path = "/etc/httpd/conf.d/nagios.conf"
      $conf_dir = "/etc/nagios"
      $config_file_mode = "0644"
      $cgi_config_file = "/etc/nagios/cgi.cfg"
    }
    default: {
      fail("Nagios module only supports Debian and Redhat (alpha) linux distributions")
    }
  }

}
