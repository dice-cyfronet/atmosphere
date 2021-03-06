require 'fog/aws/compute'
require 'fog/aws/models/compute/flavor'
require 'fog/aws/models/compute/image'
require 'fog/aws/models/compute/server'
require 'fog/aws/models/compute/images'

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

  def create_tags_for_vm(server_id, tags_map)
    create_tags(server_id, tags_map)
  end
end

class Fog::Compute::AWS::Server
  def flavor
    # Return a hash with only flavor ID defined (mimics OpenStack behavior)
    # Note: would normally return a Fog::Compute::AWS::Flavor object
    { 'id' => flavor_id }
  end

  def name
    tags['Name']
  end

  def task_state
    nil # TODO
  end

  def created
    created_at
  end

  def pause
    raise Atmosphere::UnsupportedException,
          'Amazon des not support pause action'
  end

  def suspend
    raise Atmosphere::UnsupportedException,
          'Amazon des not support suspend action'
  end
end

# Image class does not implement destroy method
class Fog::Compute::AWS::Image
  def destroy
    deregister
  end

  def status
    # possible states of an image in EC2: available, pending, failed
    # this maps to: active, saving and error
    case state
    when 'available'
      'active'
    when 'pending'
      'saving'
    else
      'error'
    end
  end
end

# Flavor unification classes
# Mimic OpenStack
class Fog::Compute::AWS::Flavor
  FLAVOR_VCPU_MAP = {
    't1.micro' => 1,
    't2.micro' => 1,
    'm1.small' => 1,
    'm1.medium' => 1,
    'm1.large' => 2,
    'm1.xlarge' => 4,
    'c1.medium' => 2,
    'c1.xlarge' => 8,
    'c3.large' => 2,
    'c3.xlarge' => 4,
    'c3.2xlarge' => 8,
    'c3.4xlarge' => 16,
    'c3.8xlarge' => 32,
    'g2.2xlarge' => 8,
    'hs1.8xlarge' => 16,
    'm2.xlarge' => 2,
    'm2.2xlarge' => 4,
    'm2.4xlarge' => 8,
    'cr1.8xlarge' => 32,
    'm3.medium' => 1,
    'm3.large' => 2,
    'm3.xlarge' => 4,
    'm3.2xlarge' => 8,
    'hi1.4xlarge' => 16,
    'cc1.4xlarge' => 16,
    'cc2.8xlarge' => 32,
    'cg1.4xlarge' => 16,
    'i2.xlarge' => 4,
    'i2.2xlarge' => 8,
    'i2.4xlarge' => 16,
    'i2.8xlarge' => 32,
    'r3.large' => 2,
    'r3.xlarge' => 4,
    'r3.2xlarge' => 8,
    'r3.4xlarge' => 16,
    'r3.8xlarge' => 32
  }

  def vcpus
    FLAVOR_VCPU_MAP[id] || cores
  end

  def supported_architectures
    case bits
    when 0
      'i386_and_x86_64'
    when 32
      'i386_and_x86_64'
    else 'x86_64'
    end
  end
end
