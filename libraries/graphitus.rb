#
#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Cookbook Name:: graphitus
# Resource:: graphitus
#
# Copyright 2013, Mathieu Sauve-Frankel
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

require 'json'

class Chef
  class Resource::Graphitus < Resource
    include Poise
    include Poise::Resource::SubResourceContainer

    default_action(:install)
    actions(:install)

    attribute(:path, kind_of: String, default: lazy { name })
    attribute(:owner, kind_of: String, default: "www-data")
    attribute(:group, kind_of: String, default: "www-data")
    attribute(:revision, kind_of: String, default: 'master')
    attribute(:git_url, kind_of: String, default: 'https://github.com/erezmazor/graphitus')
    attribute(:graphite_url, kind_of: String, default: 'http://localhost')
    attribute(:timezones, kind_of: Array, default: [ "America/Tijuana", "Asia/Tokyo" ])
    attribute(:minimumrefresh, kind_of: Fixnum, default: 10)

    def config_file
      ::File.join(path, "config.json")
    end

    def dashboard_list_url
      "dashboard-index.json"
    end

    def dashboard_url_template
      "${dashboardId}.json"
    end
  end

  class Provider::Graphitus < Provider
    include Poise

    def action_install
      resource_graphitus_deploy
      resource_graphitus_config
      resource_graphitus_dashboard_index
    end

    private

    def resource_graphitus_deploy
      include_recipe 'git'

      git new_resource.name do
        destination new_resource.path
        repository new_resource.git_url
        revision new_resource.revision
      end
    end

    def resource_graphitus_config
      config = {
        graphiteUrl: new_resource.graphite_url,
        dashboardListUrl: new_resource.dashboard_list_url,
        dashboardUrlTemplate: new_resource.dashboard_url_template,
        timezones: new_resource.timezones,
        minimumRefresh: new_resource.minimumrefresh
      }

      file new_resource.config_file do
        owner new_resource.owner
        group new_resource.group
        mode 0644
        content JSON.pretty_generate(config)
      end
    end

    def resource_graphitus_dashboard_index
      index = new_resource.subresources.map {|res|
        if res.is_a? Chef::Resource::GraphitusDashboard
          { id: res.name }
        end
      }
      config = {
        rows: index
      }

      file ::File.join(new_resource.path, new_resource.dashboard_list_url) do
        owner new_resource.owner
        group new_resource.group
        mode 0644
        content JSON.pretty_generate(config)
      end
    end
  end
end

