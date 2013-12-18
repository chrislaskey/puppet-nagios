class nagios::params () {

  case $::osfamily {
    'Debian': {
      $server_packages = ['nagios3']
      $service_name = 'nagios3'
      $binary_path = '/usr/sbin/nagios3'
      $conf_dir = '/etc/nagios3/conf.d'
      $config_file = '/etc/nagios3/nagios.cfg'
      $config_file_mode = '0644'
      $config_file_template = 'nagios/nagios.cfg.debian'
      $objects_dir = '/etc/nagios3/objects'

      $plugin_packages = ['nagios-plugins', 'nagios-snmp-plugins']
      $plugins_dir = '/usr/lib/nagios/plugins'

      $nrpe_plugin_packages = ['nagios-nrpe-plugin']
      $nrpe_server_packages = ['nagios-nrpe-server']
      $nrpe_service_name = 'nagios-nrpe-server'
      $nrpe_binary_path = '/usr/sbin/nagios-nrpe'
      $nrpe_config_file = '/etc/nagios/nrpe.cfg'
      $nrpe_config_dir = '/etc/nagios/nrpe.d'

      $nsca_server_packages = ['nsca']
      $nsca_client_packages = ['nsca-client']
      $nsca_service_name = 'nsca'
      $nsca_binary_path = '/usr/sbin/nsca'

      $check_mk_server_packages = ['check-mk-server']
      $check_mk_client_packages = ['check-mk-agent']

      $htpasswd_path = '/etc/nagios3/htpasswd.users'
      $http_config_path = '/etc/nagios3/apache.conf'
      $cgi_config_file = '/etc/nagios3/cgi.cfg'
      $nagios_path_name = 'nagios3'
    }
    'RedHat': {
      $server_packages = ['nagios']
      $service_name = 'nagios'
      $binary_path = '/usr/sbin/nagios'
      $conf_dir = '/etc/nagios/conf.d'
      $config_file = '/etc/nagios/nagios.cfg'
      $config_file_mode = '0644'
      $config_file_template = 'nagios/nagios.cfg.redhat'
      $objects_dir = '/etc/nagios/objects'

      $plugin_packages = ['nagios-plugins', 'nagios-plugins-snmp']
      $plugins_lib = $::architecture ? { 'x86_64' => 'lib64', default => 'lib' }
      $plugins_dir = "/usr/${plugins_lib}/nagios/plugins"

      $nrpe_plugin_packages = ['nagios-plugins-nrpe']
      $nrpe_server_packages = ['nrpe']
      $nrpe_service_name = 'nrpe'
      $nrpe_binary_path = '/usr/sbin/nrpe'
      $nrpe_config_file = '/etc/nagios/nrpe.cfg'
      $nrpe_config_dir = '/etc/nrpe.d'

      $nsca_server_packages = ['nsca']
      $nsca_client_packages = ['nsca-client']
      $nsca_service_name = 'nsca'
      $nsca_binary_path = '/usr/sbin/nsca'

      $check_mk_server_packages = ['check-mk']
      $check_mk_client_packages = ['check-mk-agent']

      $htpasswd_path = '/etc/nagios/passwd'
      $http_config_path = '/etc/httpd/conf.d/nagios.conf'
      $cgi_config_file = '/etc/nagios/cgi.cfg'
      $nagios_path_name = 'nagios'
    }
    default: {
      fail('Nagios module only supports Debian and Redhat linux distributions')
    }
  }

}
