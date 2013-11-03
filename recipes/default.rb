#
# Cookbook Name:: supervisor
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "logrotate"
include_recipe "python"

python_pip "supervisor" do
  action :upgrade
  version node['supervisor']['version'] if node['supervisor']['version']
end

directory node['supervisor']['dir'] do
  owner "root"
  group(node[:common_writable_group] || "root")
  mode "775"
end

template "/etc/supervisord.conf" do
  source "supervisord.conf.erb"
  owner "root"
  group "root"
  mode "644"
  variables({
    :inet_port => node['supervisor']['inet_port'],
    :inet_username => node['supervisor']['inet_username'],
    :inet_password => node['supervisor']['inet_password'],
    :supervisord_minfds => node['supervisor']['minfds'],
    :supervisord_minprocs => node['supervisor']['minprocs'],
    :supervisor_version => node['supervisor']['version'],
  })
end

directory node['supervisor']['log_dir'] do
  owner "root"
  group "root"
  mode "755"
  recursive true
end

template "/etc/init.d/supervisor" do
  source "supervisor.init.erb"
  owner "root"
  group "root"
  mode "755"
end

case node['platform']
when "debian", "ubuntu"
  template "/etc/default/supervisor" do
    source "supervisor.default.erb"
    owner "root"
    group "root"
    mode "644"
  end
end

service "supervisor" do
  action [:enable, :start]
end

# Cleanup from previous Chef cookbook where things were named "supervisord"
# instead of "supervisor".
if File.exists?("/etc/init.d/supervisord")
  file "/etc/init.d/supervisord" do
    action :delete
  end

  service "supervisord" do
    action [:stop, :disable]
  end
end

logrotate_app "supervisor" do
  path ["#{node[:supervisor][:log_dir]}/*.log", node[:supervisor][:logrotate][:extra_paths]].flatten
  frequency "daily"
  rotate node[:supervisor][:logrotate][:rotate]
  create "644 root root"
  options %w(missingok compress delaycompress notifempty)
  sharedscripts true

  # Send SIGUSR2 signal to tell supervisord to reopen all log files.
  postrotate "kill -USR2 `supervisorctl pid`"
end
