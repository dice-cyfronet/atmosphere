require 'fog/azure/compute'
require 'fog/azure/models/compute/images'
require 'fog/azure/models/compute/server'
require 'fog/azure/models/compute/servers'

class Fog::Compute::Azure::Server
  def stop
    raise Atmosphere::UnsupportedException, 'Azure des not support stop action'
  end

  def suspend
    shutdown
  end

  def pause
    raise Atmosphere::UnsupportedException, 'Azure des not support pause action'
  end

  def id
    identity
  end

  def flavor
    { 'id' => flavor_id }
  end

  def image_id
    attributes[:image]
  end

  def created
    vm = Atmosphere::VirtualMachine.find_by(id_at_site: id)
    vm ? vm.created_at : (Atmosphere.childhood_age - 1).seconds.ago
  end

  def task_state
    nil
  end

  def flavor_id
    attributes[:vm_size]
  end
end

class Fog::Compute::Azure::Servers
  def destroy(id_at_site)
    # get requires both identity and cloud service name params
    # in our case id == cloud service name
    server = all.detect { |s| s.name == id_at_site }
    server ? server.destroy : false
  end
end

class Fog::Compute::Azure::Images
  alias_method :all_orig, :all

  def all(_filters = nil)
    all_orig.select { |tmpl| tmpl.category == 'User' }
  end
end

class Fog::Compute::Azure::Image
  def id
    identity
  end

  def architecture
    'x86_64'
  end

  def status
    'active'
  end

  def tags
    {}
  end
end

class Fog::Compute::Azure::Real
  def save_template(_instance_id, _tmpl_name)
    raise Atmosphere::UnsupportedException, 'Azure des not support saving vms'
  end

  def import_key_pair(_name, _public_key)
    # do nothing since Azure does not support ssh keys
  end

  def create_tags_for_vm(_server_id, _tags_map)
    # do nothing since Azure does not support tagging
  end
end
