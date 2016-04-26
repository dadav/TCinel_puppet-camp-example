require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'client.rb'))

Puppet::Type.newtype(:nexus3_repository) do
  desc 'Manage hosted repositories in Nexus 3'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the hosted repository'
  end

  newproperty(:online) do
    desc 'Determines repository availability'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| Nexus3::Util.munge_boolean(value) }
  end

end
