Puppet::Type.newtype(:nexus3_repository) do
  desc 'Manage hosted repositories in Nexus 3'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the hosted repository'
  end

end
