Puppet::Type.newtype(:nexus3_repository) do

  ensurable

  newparam(:name, :namevar => true) do
  end

end
