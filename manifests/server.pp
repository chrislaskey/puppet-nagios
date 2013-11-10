class nagios::server (
	http = true,
	http_username = undef,
	http_password = undef,
	http_encryption = "md5",
){

	# Verify passed parameters

	if $http {
		if ! $http_username {
			fail("If http is enabled, a http_username is required.")
		}
		if ! $http_password {
			fail("If http is enabled, a http_password is required.")
		}
	}

	case $http_encryption {
		"md5":   { $http_encryption_flag = "-m" }
		"sha":   { $http_encryption_flag = "-s" }
		"crypt": { $http_encryption_flag = "-d" }
		default: { $http_encryption_flag = "-m" }
	}

	# Set OS specific variables

	case $::osfamily {
		"Debian": {
			$nagios_service_name = "nagios3"
			$nagios_binary_path = "/usr/sbin/nagios3"
			$http_htpasswd_path = "/etc/nagios3/htpasswd.users"
			$http_config_path = "/etc/nagios3/apache.conf"
			$exported_resources_target = "/etc/nagios3/conf.d/"
			$nagios_config_file_mode = "0644"
			$nagios_cgi_config_file = "/etc/nagios3/cgi.cfg"
		}
		"RedHat": {
			$nagios_service_name = "nagios"
			$nagios_binary_path = "/usr/sbin/nagios"
			$http_htpasswd_path = "/etc/nagios/.htpasswd"
			$http_config_path = "/etc/httpd/conf.d/nagios.conf"
			$exported_resources_target = "/etc/nagios/"
			$nagios_config_file_mode = "0600"
			$nagios_cgi_config_file = "/etc/nagios/cgi.cfg"
		}
		default: {
			fail("Nagios module only supports Debian and Redhat (alpha) linux distributions")
		}
	}

	# Nagios Packages

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

	Nagios_host <<| |>> {
		target => "${exported_resources_target}/nagios_host.cfg",
		require => Package["nagios-server"],
		notify => File["${exported_resources_target}/nagios_host.cfg"],
	}

	file { "${exported_resources_target}/nagios_host.cfg":
		# On Debian permissions need to be 0644 not default 0600
		ensure => "present",
		mode => $nagios_config_file_mode,
		owner => "root",
		group => "root",
		require => Package["nagios-server"],
		notify => Service["nagios-server"],
	}

	Nagios_service <<| |>> {
		target => "${exported_resources_target}/nagios_service.cfg",
		require => Package["nagios-server"],
		notify => File["${exported_resources_target}/nagios_service.cfg"],
	}

	file { "${exported_resources_target}/nagios_service.cfg":
		# On Debian permissions need to be 0644 not default 0600
		ensure => "present",
		mode => $nagios_config_file_mode,
		owner => "root",
		group => "root",
		require => Package["nagios-server"],
		notify => Service["nagios-server"],
	}

}
