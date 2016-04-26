require 'puppet'
require 'yaml'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'nexus_client.rb'))

module Nexus3
  class Client

    def self.remote(*args, &block)
      nexus_client.extdirect_client.remote(*args, &block)
    end

    def self.nexus_client
      @@nexus_client ||= begin
        Nexus3::NexusClient.new(
          get_config['base_url'],
          get_config['admin_user'],
          get_config['admin_password'],
        )
      end
    end

    def self.get_config
      @@config ||= YAML.load_file(File.expand_path(File.join(Puppet.settings[:confdir], '/nexus3_conf.yaml')))
    end

  end
end
