#
# Cookbook Name:: supervisor
# Recipe:: default
#
# Copyright 2011, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "logrotate"
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

directory "/etc/supervisord.d" do
  owner "root"
  group(node[:common_writable_group] || "root")
  mode "0775"
end

template "/etc/supervisord.conf" do
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

template "/etc/init.d/supervisord" do
  source "supervisord.init.erb"
  mode "0755"
end

service "supervisord" do
  supports :status => true, :restart => true
  action [:enable, :start]
end

logrotate_app "supervisor" do
  path "/var/log/supervisor/*.log"
  rotate 7
end
