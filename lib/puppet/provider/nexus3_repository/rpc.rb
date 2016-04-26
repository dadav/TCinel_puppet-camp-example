require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'client.rb'))

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
    result = Nexus3::Client.remote('coreui_Repository', 'create',
      [MAVEN_REPO_SKELETON.merge({:name => resource[:name]})]
    )
  end

  def destroy
    result = Nexus3::Client.remote('coreui_Repository', 'remove', [resource[:name]])
  end

end
