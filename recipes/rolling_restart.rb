#
# Cookbook Name:: supervisor
# Recipe:: rolling_restart
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

# Perform smarter restarts, so only one process in a group is down at a time.
template "/usr/local/bin/supervisorctl_rolling_restart" do
  source "supervisorctl_rolling_restart.erb"
  mode "0755"
end
