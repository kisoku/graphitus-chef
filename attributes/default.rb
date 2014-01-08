# Cookbook Name:: graphitus
# Resource:: graphitus
#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Mathieu Sauve-Frankel
# Copyright 2013, Balanced, Inc.
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

default['graphitus']['listen_ports'] = [80]
default['graphitus']['hostname'] = nil # node['fqdn']
default['graphitus']['ssl_enabled'] = false
default['graphitus']['ssl_redirect_http'] = true
default['graphitus']['ssl_listen_ports'] = [443]
default['graphitus']['ssl_path'] = nil # node['berkshelf-api']['path']}/ssl
default['graphitus']['ssl_cert_path'] = nil # node['berkshelf-api']['proxy']['ssl_path']/berkshelf-api.pem
default['graphitus']['ssl_key_path'] = nil # node['berkshelf-api']['proxy']['ssl_path']/berkshelf-api.key
default['graphitus']['provider'] = nil # Auto-detects based on available cookbooks

# ಠ_ಠ ಠ_ಠ ಠ_ಠ ಠ_ಠ ಠ_ಠ
override['apache']['default_site_enabled'] = false
override['nginx']['default_site_enabled'] = false
