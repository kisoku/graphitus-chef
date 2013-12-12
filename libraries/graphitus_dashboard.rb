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

DASHBOARD_ATTRIBUTES = %w[
  title columns width height user timeback from until legend
  refresh refreshintervalseconds defaultlinewidth tz data parameters
]

class Chef
  class Resource::GraphitusDashboard < Resource
    include Poise
    poise_subresource(Graphitus)

    default_action(:create)
    actions(:create)

    attribute(:title, kind_of: String, default: lazy { name })
    attribute(:columns, kind_of: Fixnum, required: true)
    attribute(:width, kind_of: Fixnum, required: true)
    attribute(:height, kind_of: Fixnum, required: true)
    attribute(:user, kind_of: String)
    attribute(:timeback, kind_of: String)
    attribute(:from, kind_of: String)
    attribute(:until, kind_of: String)
    attribute(:legend, kind_of: String)
    attribute(:refresh, kind_of: [TrueClass, FalseClass], default: true)
    attribute(:refreshintervalseconds, kind_of: Fixnum)
    attribute(:defaultlinewidth, kind_of: Fixnum)
    attribute(:tz, kind_of: String)
    attribute(:data, kind_of: Array)
    attribute(:parameters, kind_of: Hash)

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
      config = ::DASHBOARD_ATTRIBUTES.map {|attr|
        if (new_resource.respond_to?(attr) && !new_resource.send(attr).nil?)
          [attr, new_resource.send(attr)]
        else
          nil
        end
      }.compact.flatten
      config = Hash[*config]

      file new_resource.path do
        owner new_resource.parent.owner
        group new_resource.parent.group
        mode "0644"
        content ::JSON.pretty_generate(config)
      end
    end
  end
end
