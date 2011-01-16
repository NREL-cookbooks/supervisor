#
# Cookbook Name:: supervisor
# Recipe:: default
#
# Copyright 2011, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "python"

#
# Package Installation
#

easy_install_package "supervisor" do
  version node[:supervisor][:version]
end

#
# Default Configuration
#

directory "/etc/supervisor" do
  owner "root"
  group "root"
  mode "0755"
end

directory "/etc/supervisor/conf.d" do
  owner "root"
  group(node[:common_writable_group] || "root")
  mode "0775"
end

template "/etc/supervisor/supervisord.conf" do
  source "supervisord.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[supervisord]"
end

directory "/var/log/supervisor" do
  owner "root"
  group "root"
  mode "0755"
end

#
# Upstart service configuration
#

upstart_conf_path = "/etc/init/supervisord.conf"
if(node[:platform] == "ubuntu" && node[:platform_version].to_f <= 9.04)
  upstart_conf_path = "/etc/event.d/supervisord"
end

template upstart_conf_path do
  source "upstart.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[supervisord]"
end

service "supervisord" do
  provider Chef::Provider::Service::Upstart
  action :start
end
