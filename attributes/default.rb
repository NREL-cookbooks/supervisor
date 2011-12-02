default[:supervisor][:version] = "3.0a10"
default[:supervisor][:log_dir] = "/var/log/supervisor"
default[:supervisor][:pid_file] = "/var/run/supervisord.pid"

# Logrotate Settings
default[:supervisor][:logrotate][:extra_paths] = []
default[:supervisor][:logrotate][:rotate] = 90
