require 'fog/openstack/compute'

# open stack client does not provide import_key_pair method
# while aws does
# It is desired that both aws and openstack client provide identical api hence the magic :-)
class Fog::Compute::OpenStack::Real
  def import_key_pair(name, public_key)
    create_key_pair(name, public_key)
  end
end