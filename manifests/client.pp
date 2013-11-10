class nagios::client (
	# Accepts either a string or array of values, e.g. ["1.1.1.1", "1.1.1.2"]
	allowed_hosts = "127.0.0.1",
){

	# Variables

	if is_array($allowed_hosts) {
		$allowed_hosts_string = join($allowed_hosts, ",")
	} elsif is_string($allowed_hosts) {
		$allowed_hosts_string = $allowed_hosts
	} else {
		fail("The 'allowed_hosts' parameter must either be a string or an array")
	}

	# Packages

	package { "nagios-client":
		name => [
			"nagios-plugins",
			"nagios-nrpe-server",
		],
		ensure => "present",
	}

	# Config files

	file { "/etc/nagios/nrpe.cfg":
		ensure => "present",
		content => template("nagios/nrpe.cfg"),
		owner => "root",
		group => "root",
		mode => "0644",
		require => [
			Package["nagios-client"],
		],
	}

	# TODO: Create config file, export it so Nagios host can load it.
	#
	# Solve the problem that multiple block definitions "define host {}, define service {}" 
	# in the config file need to go into one file.
	# Research if they can go in multiple files?

}
