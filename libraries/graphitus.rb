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

require 'json'

class Chef
  class Resource::Graphitus < Resource
    include Poise
    include Poise::Resource::SubResourceContainer

    actions(:install)

    attribute('', template: true)
    attribute(:path, kind_of: String, default: lazy { "/srv/#{name}" })
    attribute(:hostname, kind_of: String, default: lazy { node['fqdn'] })
    attribute(:owner, kind_of: String, default: 'www-data')
    attribute(:group, kind_of: String, default: 'www-data')
    attribute(:revision, kind_of: String, default: 'master')
    attribute(:git_url, kind_of: String, default: 'https://github.com/erezmazor/graphitus')
    attribute(:graphite_url, kind_of: String, default: 'http://localhost')
    attribute(:timezones, kind_of: Array, default: [ 'America/Tijuana', 'Asia/Tokyo' ])
    attribute(:minimumrefresh, kind_of: Fixnum, default: 10)
    attribute(:dashboard_index_file, kind_of: String, default: 'dashboard-index.json')
    attribute(:dashboard_index_url, kind_of: String, default: '${dashboardId}.json')
    attribute(:listen_ports, kind_of: Array, default: lazy { node['graphitus']['listen_ports'] })
    attribute(:ssl_redirect_http, equal_to: [true, false], default: lazy { node['graphitus']['ssl_redirect_http'] })
    attribute(:ssl_listen_ports, kind_of: Array, default: lazy { node['graphitus']['ssl_listen_ports'] })
    attribute(:ssl_enabled, equal_to: [true, false], default: lazy { node['graphitus']['ssl_enabled'] })
    attribute(:ssl_cert, kind_of: String)
    attribute(:ssl_key, kind_of: String)
    attribute(:ssl_cert_path, kind_of: String, default: '/etc/ssl/certs/graphitus.pem')
    attribute(:ssl_key_path, kind_of: String, default: '/etc/ssl/private/graphitus.key')

    def fs_friendly_name
      name.downcase.gsub(/[\s\/|]/, "_")
    end

    def dashboard_list_url
      "dashboard-index.json"
    end

    def dashboard_url_template
      "${dashboardId}.json"
    end

    def provider(arg=nil)
      if arg.kind_of?(String) || arg.kind_of?(Symbol)
        class_name = Mixin::ConvertToClassName.convert_to_class_name(arg.to_s)
        arg = Provider::Graphitus.const_get(class_name) if Provider::Graphitus.const_defined?(class_name)
      end
      super(arg)
    end

    def provider_for_action(*args)
      unless provider
        if node['graphitus']['provider']
          provider(node['graphitus']['provider'].to_sym)
        elsif default_provider = self.class.default_provider(node)
          provider(default_provider)
        else
          raise 'Unable to autodetect proxy provider, please specify one'
        end
      end
      super
    end

    def self.default_provider(node)
      # I would rather check if the cookbook is present, but this will have to do for now.
      # Checking run_context.cookbook_collection.include? fails because for solo it just blindly
      # loads everything in the cookbook_path.
      if node['recipes'].include?('apache2')
        :apache
      elsif node['recipes'].include?('nginx')
        :nginx
      end
    end
  end

  class Provider::Graphitus < Provider
    include Poise

    def action_install
      converge_by("install a graphitus instance named #{Array(new_resource.hostname).join(', ')}") do
        notifying_block do
          install_server
          # create_ssl_dir
          install_cert
          install_key
          install_graphitus
          configure_graphitus
          configure_server
          create_graphitus_dashboard_index
          enable_vhost
        end
        new_resource.notifies(:reload, run_context.resource_collection.find(service_resource))
      end
    end

    private

    def graphitus_config_path
      ::File.join(new_resource.path, "config.json")
    end

    def install_server
      raise NotImplementedError
    end

    def server_config_path
      raise NotImplementedError
    end

    def server_config_source
      raise NotImplementedError
    end

    def service_resource
      raise NotImplementedError
    end

    def install_graphitus
      include_recipe 'git'

      git new_resource.name do
        destination new_resource.path
        repository new_resource.git_url
        revision new_resource.revision
      end
    end

    def create_ssl_dir
      if new_resource.ssl_enabled
        directory new_resource.ssl_path do
          owner 'root'
          group 'root'
          mode '700'
        end
      end
    end

    def install_cert
      if new_resource.ssl_enabled && new_resource.ssl_cert
        file new_resource.ssl_cert_path do
          owner 'root'
          group 'root'
          mode '600'
          content new_resource.ssl_cert
        end
      end
    end

    def install_key
      if new_resource.ssl_enabled && new_resource.ssl_key
        file new_resource.ssl_key_path do
          owner 'root'
          group 'root'
          mode '600'
          content new_resource.ssl_key
        end
      end
    end

    def configure_server
      if !new_resource.source && !new_resource.content(nil, true)
        new_resource.source(server_config_source)
        new_resource.cookbook('graphitus')
      end
      file server_config_path do
        content new_resource.content
        owner new_resource.owner
        group new_resource.group
        mode '0644'
      end
    end

    def configure_graphitus
      config = {
        graphiteUrl: new_resource.graphite_url,
        dashboardListUrl: new_resource.dashboard_index_file,
        dashboardUrlTemplate: new_resource.dashboard_url_template,
        timezones: new_resource.timezones,
        minimumRefresh: new_resource.minimumrefresh
      }

      file graphitus_config_path do
        owner new_resource.owner
        group new_resource.group
        mode 0644
        content JSON.pretty_generate(config)
      end
    end

    def create_graphitus_dashboard_index
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

  class Provider::Graphitus::Apache < Chef::Provider::Graphitus

    private

    def install_server
      include_recipe 'apache2'
      include_recipe 'apache2::mod_rewrite'
      include_recipe 'apache2::mod_ssl' if new_resource.ssl_enabled
    end

    def server_config_path
      ::File.join(node['apache']['dir'], 'sites-available', "graphitus-#{new_resource.fs_friendly_name}.conf")
    end

    def server_config_source
      'apache.conf.erb'
    end

    def service_resource
      'service[apache2]'
    end

    def enable_vhost
      apache_site "graphitus-#{new_resource.fs_friendly_name}.conf" do
        enable true
      end
    end
  end
end

