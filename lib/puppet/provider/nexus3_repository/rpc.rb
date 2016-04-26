require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'util.rb'))

Puppet::Type.type(:nexus3_repository).provide(:rpc) do
  MAVEN_REPO_SKELETON = {
    :attributes => {
      :maven => {
        :versionPolicy => :RELEASE,
        :layoutPolicy => :STRICT,
      },
      :storage => {
        :blobStoreName => :default,
        :strictContentTypeValidation => :true,
        :writePolicy => :ALLOW_ONCE,
      },
    },
    :format => '',
    :type => '',
    :url => '',
    :online => :true,
    :recipe => 'maven2-hosted',
  }

  def initialize(value={})
    super(value)
    @flush_required = false
  end

  def self.instances
    repositories = Nexus3::Client.remote('coreui_Repository', 'read', nil)['result']['data']

    repositories.select { |repository|
      repository['recipe'] == 'maven2-hosted'
    }.collect { |repository|
      new(
        :ensure => :present,
        :name   => repository['name'],
        :online => Nexus3::Util.munge_boolean(repository['online']),
      )
    }
  end

  def self.prefetch(resources)
    repositories = instances
    resources.keys.each do |name|
      if provider = repositories.find { |repository| repository.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Nexus3::Client.remote('coreui_Repository', 'create', map_resource_to_data)
    Puppet::debug("nexus3_repository create result: #{result}")
  end

  def destroy
    result = Nexus3::Client.remote('coreui_Repository', 'remove', [resource[:name]])
    Puppet::debug("nexus3_repository destroy result: #{result}")
  end

  def flush
    if @flush_required
      result = Nexus3::Client.remote('coreui_Repository', 'update', map_resource_to_data)

      Puppet::debug("nexus3_repository update result: #{result}")
      fail() unless result['result']['success']

      @property_hash = resource.to_hash
    end
  end

  def map_resource_to_data
    [
      MAVEN_REPO_SKELETON.merge(
        {
          :name   => resource[:name],
          :online => Nexus3::Util.sym_to_bool(resource[:online]),
        }
      )
    ]
  end

  def online
    @property_hash[:online]
  end

  def online=(value)
    @flush_required = true
  end

end
