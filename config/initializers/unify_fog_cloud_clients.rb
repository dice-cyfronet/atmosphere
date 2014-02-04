require 'fog/openstack/compute'
require 'fog/openstack/models/compute/server'
require 'fog/aws/compute'
require 'fog/aws/models/compute/image'
require 'fog/aws/models/compute/server'

# open stack client does not provide import_key_pair method
# while aws does
# It is desired that both aws and openstack client provide identical api hence the magic :-)
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
end


class Fog::Compute::OpenStack::Server

  def image_id
    image['id']
  end

  def task_state
    os_ext_sts_task_state
  end
end

class Fog::Compute::AWS::Real
  def save_template(instance_id, tmpl_name)
    resp = create_image(instance_id, tmpl_name, nil)
    if resp.status == 200
      resp.body['imageId']
    else
      # TODO raise specific exc
      raise "Failed to save vm #{instance_id} as template"
    end
  end
  def reboot_server(server_id)
    reboot_instances([server_id])
  end
end

class Fog::Compute::AWS::Server

  def name
    tags['Name']
  end

  def task_state
    nil #TODO
  end
end

# Image class does not implement destroy method
class Fog::Compute::AWS::Image
  def destroy
    deregister
  end

  def status
    ready? ? 'ACTIVE' : 'DELETED'
  end
end
