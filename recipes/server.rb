#
# Cookbook Name::       redis
# Description::         Redis server with runit service
# Recipe::              server
# Author::              Benjamin Black
#
# Copyright 2011, Benjamin Black
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

include_recipe 'runit'
case node[:redis][:installation_preference]
when "upstream"
  include_recipe "redis::install_from_upstream"
#when "launchpad"
# TODO: Broken, not implemented as it's 2.4.9
#  include_recipe "redis::install_from_launchpad"
else
  include_recipe "redis::install_from_package"
end

# if we have over 8GB of memory we enable overcommit.
if node[:memory][:total].to_i > 8169948
  sysctl "vm.overcommit_memory" do
    variables 'vm.overcommit_memory' => 1
  end
else
  log "redis:vm_overcommit_memory=> 0"
end

user node[:redis][:user] do
  uid node[:redis][:uid]
  gid node[:redis][:gid]
  password nil
  shell "/bin/false"
  home node[:redis][:data_dir]
  supports :manage_home => false
  action :create
end

%w(data_dir log_dir conf_dir).each do |p|
  directory node[:redis][p] do
    action :create
    recursive true
    owner node[:redis][:user]
    group node[:redis][:user]
    mode 0755
  end
end

template "#{node[:redis][:conf_dir]}/redis.conf" do
  source        "redis.conf.erb"
  owner         "root"
  group         "root"
  mode          "0644"
  variables     :redis => node[:redis], :redis_server => node[:redis][:server]
end

runit_service "redis_server" do
  run_state     node[:redis][:server][:run_state]
  options       node[:redis]
end
