require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'util.rb'))

Puppet::Type.type(:nexus3_repository).provide(:rpc) do
  MAVEN_REPO_SKELETON = {
  }

  def initialize(value={})
    super(value)
    @flush_required = false
  end

  def self.instances
    repositories = Nexus3::Client.remote('coreui_Repository', 'read', nil)['result']['data']

    repositories.select { |repository|
      Puppet::debug("Considering repository: #{repository['name']}")
      repository['recipe'] == 'maven2-hosted'
    }.collect { |repository|
      Puppet::debug("Selected repository: #{repository}")
      new(
        :ensure    => :present,
        :name      => repository['name'],
        :online    => Nexus3::Util.munge_boolean(repository['online']),
        :blobstore => repository['attributes']['storage']['blobStoreName'],
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
    check_operation_result('create', result)
  end

  def destroy
    result = Nexus3::Client.remote('coreui_Repository', 'remove', [resource[:name]])
    check_operation_result('destroy', result)
  end

  def flush
    if @flush_required
      result = Nexus3::Client.remote('coreui_Repository', 'update', map_resource_to_data)
      check_operation_result('flush', result)

      @property_hash = resource.to_hash
    end
  end

  def check_operation_result(operation, result)
    Puppet::debug("nexus3_repository #{operation} result: #{result}")
    unless result['result']['success']
      fail("Failed to #{operation} nexus3_repository") 
      raise Puppet::Error, "#{operation} failed"
    end
  end

  def map_resource_to_data
    [
        {
          :name    => resource[:name],
          :online  => Nexus3::Util.sym_to_bool(resource[:online]),
          :attributes => {
            :maven => {
              :versionPolicy => :RELEASE,
              :layoutPolicy => :STRICT,
            },
            :storage => {
              :blobStoreName => resource[:blobstore],
              :strictContentTypeValidation => :true,
              :writePolicy => :ALLOW_ONCE,
            },
          },
          :format => '',
          :type => '',
          :url => '',
          :recipe => 'maven2-hosted',
        }
    ]
  end

  def online
    @property_hash[:online]
  end

  def online=(value)
    @flush_required = true
  end

  def blobstore
    @property_hash[:blobstore]
  end

  def blobstore=(value)
    fail('blobstore property is immutable')
  end

end
