require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'client.rb'))

Puppet::Type.newtype(:nexus3_blobstore) do

  desc 'Manage blobstores in Nexus 3'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the blobstore'
  end

  newproperty(:type) do
    desc 'Determines blobstore type'
    newvalues(:File)
    defaultto :File
  end

  newparam(:path) do
    desc 'Absolute path to blobstore directory for file-type blobstores'
  end

  validate do
    if self[:ensure] == :present
      unless /[a-zA-Z0-9_\-.\/]+/ =~ self[:path]
        fail("path: Only non-empty strings containing alphanumerics, forward slashes, periods, hyphens and underscores are allowed (#{self[:path]} given).")
      end
    end
  end

  autorequire(:file) do
    Nexus3::Client.config_path
  end

end
