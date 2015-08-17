require 'fog/openstack/compute'
require 'fog/openstack/models/compute/server'
require 'fog/openstack/models/compute/servers'
require 'fog/openstack/models/compute/flavor'
require 'fog/openstack/models/compute/image'
require 'fog/openstack/models/compute/images'

# open stack client does not provide import_key_pair method
# while aws does. It is desired that both aws and openstack client
# provide identical api hence the magic :-)
class Fog::Compute::OpenStack::Real
  def import_key_pair(name, public_key)
    create_key_pair(name, public_key)
  end

  # alias does not work since create_key_pair method is also added using magic
  # alias :import_key_pair :create_key_pair

  # AWS and openstack create_image methods have different signatures...
  def save_template(instance_id, tmpl_name)
    resp = create_image(instance_id, tmpl_name)
    if resp.status == 200
      resp.body['image']['id']
    else
      # TODO raise specific exc
      raise "Failed to save vm #{instance_id} as template"
    end
  end

  def create_tags_for_vm(server_id, tags_map)
    set_metadata('servers', server_id, tags_map)
  end
end

class Fog::Compute::OpenStack::Flavor
  def supported_architectures
    'x86_64'
  end
end

class Fog::Compute::OpenStack::Servers
  def destroy(id_at_site)
    vm = get(id_at_site)

    !vm || vm.destroy
  end
end

class Fog::Compute::OpenStack::Server
  def image_id
    image['id']
  end

  def task_state
    os_ext_sts_task_state
  end
end

class Fog::Compute::OpenStack::Image
  def architecture
    'x86_64'
  end

  def tags
    metadata.to_hash
  end
end
