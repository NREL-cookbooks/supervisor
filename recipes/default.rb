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

# foodcritic FC023: we prefer not having the resource on non-smartos
if platform_family?("smartos")
  package "py27-expat" do
    action :install
  end
end

# Until pip 1.4 drops, see https://github.com/pypa/pip/issues/1033
python_pip "setuptools" do
  action :upgrade
end

python_pip "supervisor" do
  action :upgrade
  version node['supervisor']['version'] if node['supervisor']['version']
end

directory node['supervisor']['dir'] do
  owner "root"
  group(node[:common_writable_group] || "root")
  mode "775"
end

template node['supervisor']['conffile'] do
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

case node['platform_family']
when "debian"
  template "/etc/init.d/supervisor" do
    source "supervisor.init.erb"
    owner "root"
    group "root"
    mode "755"
  end

  template "/etc/default/supervisor" do
    source "supervisor.default.erb"
    owner "root"
    group "root"
    mode "644"
  end

  service "supervisor" do
    action [:enable, :start]
  end
when "rhel"
  template "/etc/init.d/supervisor" do
    source "supervisor.init.erb"
    owner "root"
    group "root"
    mode "755"
  end

  service "supervisor" do
    action [:enable, :start]
  end
when "smartos"
  directory "/opt/local/share/smf/supervisord" do
    owner "root"
    group "root"
    mode "755"
  end

  template "/opt/local/share/smf/supervisord/manifest.xml" do
    source "manifest.xml.erb"
    owner "root"
    group "root"
    mode "644"
    notifies :run, "execute[svccfg-import-supervisord]", :immediately
  end

  execute "svccfg-import-supervisord" do
    command "svccfg import /opt/local/share/smf/supervisord/manifest.xml"
    action :nothing
  end

  service "supervisord" do
    action [:enable]
  end
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
