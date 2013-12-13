class nagios::params () {

  case $::osfamily {
    'Debian': {
      $server_packages = ['nagios3', 'nagios-plugins', 'nagios-snmp-plugins']
      $client_packages = ['nagios-plugins', 'nagios-snmp-plugins']

      $nrpe_server_packages = ['nagios-nrpe-server']
      $nrpe_client_packages = ['nagios-nrpe-plugin']
      $nsca_server_packages = ['nsca']
      $nsca_client_packages = ['nsca-client']
      $check_mk_server_packages = ['check-mk-server']
      $check_mk_client_packages = ['check-mk-agent']

      $service_name = 'nagios3'
      $binary_path = '/usr/sbin/nagios3'
      $conf_dir = '/etc/nagios3/conf.d'
      $config_file_mode = '0644'

      $htpasswd_path = '/etc/nagios3/htpasswd.users'
      $http_config_path = '/etc/nagios3/apache.conf'
      $cgi_config_file = '/etc/nagios3/cgi.cfg'
    }
    'RedHat': {
      $server_packages = ['nagios', 'nagios-plugins', 'nagios-plugins-all']
      $client_packages = ['nagios-plugins']

      $nrpe_server_packages = ['nrpe', 'nagios-plugins-nrpe']
      $nrpe_client_packages = ['nagios-plugins-nrpe']
      $nsca_server_packages = ['nsca']
      $nsca_client_packages = ['nsca-client']
      $check_mk_server_packages = ['check-mk']
      $check_mk_client_packages = ['check-mk-agent']

      $service_name = 'nagios'
      $binary_path = '/usr/sbin/nagios'
      $conf_dir = '/etc/nagios'
      $config_file_mode = '0644'

      $htpasswd_path = '/etc/nagios/.htpasswd'
      $http_config_path = '/etc/httpd/conf.d/nagios.conf'
      $cgi_config_file = '/etc/nagios/cgi.cfg'
    }
    default: {
      fail('Nagios module only supports Debian and Redhat (alpha) linux distributions')
    }
  }

}
