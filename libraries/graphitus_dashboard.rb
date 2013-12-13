#
#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Cookbook Name:: graphitus
# Resource:: graphitus_dashboard
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

DASHBOARD_ATTRIBUTE_MAP = {
  title: "title",
  columns: "columns",
  width: "width",
  height: "height",
  user: "user",
  timeback: "timeBack",
  from: "from",
  until: "until",
  legend: "legend",
  refresh: "refresh",
  refreshintervalseconds: "refreshIntervalSeconds",
  defaultlinewidth: "defaultLineWidth",
  tz: "tz",
  averageseries: "averageSeries",
  data: "data",
  parameters: "parameters"
}

class Chef
  class Resource::GraphitusDashboard < Resource
    include Poise
    poise_subresource(Graphitus)

    default_action(:create)
    actions(:create)

    attribute(:title, kind_of: String, default: lazy { name })
    attribute(:columns, kind_of: Fixnum, default: 2)
    attribute(:width, kind_of: Fixnum, default: 700)
    attribute(:height, kind_of: Fixnum, default: 350)
    attribute(:user, kind_of: String)
    attribute(:timeback, kind_of: String, default: '24h')
    attribute(:from, kind_of: String, default: '')
    attribute(:until, kind_of: String, default: '')
    attribute(:legend, kind_of: [TrueClass, FalseClass], default: true)
    attribute(:refresh, kind_of: [TrueClass, FalseClass], default: true)
    attribute(:refreshintervalseconds, kind_of: Fixnum, default: 90)
    attribute(:defaultlinewidth, kind_of: Fixnum, default: 2)
    attribute(:tz, kind_of: String, default: 'America/Tijuana')
    attribute(:averageseries, kind_of: [TrueClass, FalseClass], default: false)
    attribute(:data, kind_of: Array, default: [])
    attribute(:parameters, kind_of: Hash, default: {})

    def json_file
      "#{name}.json"
    end

    def path
      ::File.join(parent.path, "#{name}.json")
    end
  end

  class Provider::GraphitusDashboard < Provider
    include Poise

    def action_create
      resource_dashboard_config
    end

    private

    def resource_dashboard_config
      config = {}
      ::DASHBOARD_ATTRIBUTE_MAP.each_pair {|attr,val|
        if (new_resource.respond_to?(attr) && !new_resource.send(attr).nil?)
          config[val] = new_resource.send(attr)
        end
      }

      file new_resource.path do
        owner new_resource.parent.owner
        group new_resource.parent.group
        mode "0644"
        content ::JSON.pretty_generate(config)
      end
    end
  end
end
