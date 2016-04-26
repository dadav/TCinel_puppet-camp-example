require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'client.rb'))

Puppet::Type.type(:nexus3_repository).provide(:rpc) do

  def self.instances
    repositories = Nexus3::Client.remote('coreui_Repository', 'read', nil)['result']['data']

    repositories.select { |repository|
      repository['recipe'] == 'maven2-hosted'
    }.collect { |repository|
      new(
        :ensure => :present,
        :name   => repository['name']
      )
    }
  end

  def exists?
    @property_hash[:ensure] == :present
  end

end
