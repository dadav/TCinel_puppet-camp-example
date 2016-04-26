require 'deep_merge'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'util.rb'))

Puppet::Type.type(:nexus3_blobstore).provide(:rpc) do
  BLOBSTORE_SKELETON = {
    :type       => 'File',
  }

  def initialize(value={})
    super(value)
  end

  def self.instances
    blobstores = Nexus3::Client.remote('coreui_Blobstore', 'read', nil)['result']['data']

    blobstores.collect { |blobstore|
      Puppet::debug("Selected blobstore: #{blobstore}")
      new(
        :ensure => :present,
        :name   => blobstore['name'],
        :type   => :File,
      )
    }
  end

  def self.prefetch(resources)
    blobstores = instances
    resources.keys.each do |name|
      if provider = blobstores.find { |blobstore| blobstore.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Nexus3::Client.remote('coreui_Blobstore', 'create', map_resource_to_data)
    check_operation_result('create', result)
  end

  def destroy
    result = Nexus3::Client.remote('coreui_Blobstore', 'remove', [resource[:name]])
    check_operation_result('destroy', result)
  end

  def check_operation_result(operation, result)
    Puppet::debug("nexus3_blobstore #{operation} result: #{result}")
    unless result['result']['success']
      fail("Failed to #{operation} nexus3_blobstore") 
      raise Puppet::Error, "#{operation} failed"
    end
  end

  def map_resource_to_data
    [
      BLOBSTORE_SKELETON.deep_merge(
        {
          :name       => resource[:name],
          :type       => resource[:type],
          :path       => resource[:path],
          :attributes => "{\"file\":{\"path\":\"#{resource[:path]}\"}}" 
        }
      )
    ]
  end

  def type
    @property_hash[:type]
  end

  def type=(value)
    fail('type property is immutable')
  end

  def path
    @property_hash[:path]
  end

  def path=(value)
    fail('path property is immutable')
  end

end

