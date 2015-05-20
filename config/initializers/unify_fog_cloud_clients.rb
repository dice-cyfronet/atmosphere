require 'fog/openstack/compute'
require 'fog/openstack/models/compute/server'
require 'fog/openstack/models/compute/flavor'
require 'fog/openstack/models/compute/image'
require 'fog/openstack/models/compute/images'

require 'fog/aws/compute'
require 'fog/aws/models/compute/flavor'
require 'fog/aws/models/compute/image'
require 'fog/aws/models/compute/server'
require 'fog/aws/models/compute/images'

require 'azure/virtual_machine_image_management/serialization'
require 'azure/virtual_machine_management/serialization'
require 'azure/base_management/management_http_request'
require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'
require 'fog/azure/compute'
require 'fog/azure/models/compute/images'
require 'fog/azure/models/compute/server'
require 'fog/azure/models/compute/servers'

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

  def create_tags_for_vm(server_id, tags_map)
    set_metadata('servers', server_id, tags_map)
  end
end

class Fog::Compute::OpenStack::Flavor
  def supported_architectures
    'x86_64'
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
  def create_tags_for_vm(server_id, tags_map)
    create_tags(server_id, tags_map)
  end
end

class Fog::Compute::AWS::Server

  def flavor
    # Return a hash with only flavor ID defined (mimics OpenStack behavior)
    # Note: would normally return a Fog::Compute::AWS::Flavor object
    {'id' => flavor_id}
  end

  def name
    tags['Name']
  end

  def task_state
    nil #TODO
  end

  def created
    created_at
  end

  def pause
    raise Atmosphere::UnsupportedException, 'Amazon des not support pause action'
  end

  def suspend
    raise Atmosphere::UnsupportedException, 'Amazon des not support suspend action'
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
    "t1.micro" => 1,
    "t2.micro" => 1,
    "m1.small" => 1,
    "m1.medium" => 1,
    "m1.large" => 2,
    "m1.xlarge" => 4,
    "c1.medium" => 2,
    "c1.xlarge" => 8,
    "c3.large" => 2,
    "c3.xlarge" => 4,
    "c3.2xlarge" => 8,
    "c3.4xlarge" => 16,
    "c3.8xlarge" => 32,
    "g2.2xlarge" => 8,
    "hs1.8xlarge" => 16,
    "m2.xlarge" => 2,
    "m2.2xlarge" => 4,
    "m2.4xlarge" => 8,
    "cr1.8xlarge" => 32,
    "m3.medium" => 1,
    "m3.large" => 2,
    "m3.xlarge" => 4,
    "m3.2xlarge" => 8,
    "hi1.4xlarge" => 16,
    "cc1.4xlarge" => 16,
    "cc2.8xlarge" => 32,
    "cg1.4xlarge" => 16,
    "i2.xlarge" => 4,
    "i2.2xlarge" => 8,
    "i2.4xlarge" => 16,
    "i2.8xlarge" => 32,
    "r3.large" => 2,
    "r3.xlarge" => 4,
    "r3.2xlarge" => 8,
    "r3.4xlarge" => 16,
    "r3.8xlarge" => 32
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

class Fog::Compute::OpenStack::Real
  def create_tags_for_vm(server_id, tags_map)
    # do nothing since Azure does not support tagging
  end
end

# ============ AZURE ===============

module Azure::VirtualMachineManagement::Serialization
  class << self
    alias_method :deployment_to_xml_orig, :deployment_to_xml
  end
  def self.deployment_to_xml(params, options)
    xml = self.deployment_to_xml_orig(params, options)
    puts "===========XML=============="
    puts xml
    xml
  end

  def self.role_to_xml(params, options)
    #puts "params: #{params}"
    #puts "options: #{options}"
    img_is_user_created = user_image? params[:image]
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.PersistentVMRole(
        'xmlns' => 'http://schemas.microsoft.com/windowsazure',
        'xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance'
      ) do
        xml.RoleName { xml.text params[:vm_name] }
        xml.OsVersion('i:nil' => 'true') unless img_is_user_created
        xml.RoleType 'PersistentVMRole'

        xml.ConfigurationSets do
          provisioning_configuration_to_xml(xml, params, options)
          xml.ConfigurationSet('i:type' => 'NetworkConfigurationSet') do
            xml.ConfigurationSetType 'NetworkConfiguration'
            xml.InputEndpoints do
              default_endpoints_to_xml(xml, options)
              tcp_endpoints_to_xml(
                xml,
                options[:tcp_endpoints],
                options[:existing_ports]
              ) if options[:tcp_endpoints]
            end
            if options[:virtual_network_name] && options[:subnet_name]
              xml.SubnetNames do
                xml.SubnetName options[:subnet_name]
              end
              xml.StaticVirtualNetworkIPAddress options[:static_virtual_network_ipaddress] if options[:static_virtual_network_ipaddress]
            end
          end
        end
        xml.AvailabilitySetName options[:availability_set_name] unless img_is_user_created
        # Label does not seem to be required
        #xml.Label Base64.encode64(params[:vm_name]).strip

        if img_is_user_created
          xml.VMImageName params[:image]
          xml.ProvisionGuestAgent 'true'
        else
          xml.OSVirtualHardDisk do
            if img_is_user_created
              xml.MediaLink "https://portalvhdswkd6qtd0zqkw9.blob.core.windows.net/vhds/Ubuntu_14.04.1_LTS_Apach2-os-2015-04-21.vhd"
              #'https://' + options[:storage_account_name] + '.blob.core.windows.net/' + (Time.now.strftime('disk_%Y_%m_%d_%H_%M_%S_%L')) + '.vhd'
            else
              xml.MediaLink 'http://' + options[:storage_account_name] + '.blob.core.windows.net/vhds/' + (Time.now.strftime('disk_%Y_%m_%d_%H_%M_%S_%L')) + '.vhd'
            end
            xml.SourceImageName params[:image] unless img_is_user_created
          #xml.OS 'Linux'
          end
        end
        xml.RoleSize options[:vm_size] || params[:vm_size]
      end
    end
    builder.doc
  end

  private
  def self.user_image?(image_id)
    img_svc = Azure::VirtualMachineImageManagementService.new
    img = img_svc.list_virtual_machine_images.select { |i| i.name == image_id}.first
    img.category == 'User'
  end
end

module Azure
  module VirtualMachineImageManagement
    module Serialization
      extend Azure::Core::Utility

      def self.user_virtual_machine_images_from_xml(imageXML)
        os_images = []
        virtual_machine_images = imageXML.css('VMImages VMImage')
        virtual_machine_images.each do |image_node|
          image = Azure::VirtualMachineImageManagement::VirtualMachineImage.new
          image.os_type = xml_content(image_node, 'OSDiskConfiguration OS')
          image.name = xml_content(image_node, 'Name')
          image.category = xml_content(image_node, 'Category')
          image.locations = xml_content(image_node, 'Location')
          os_images << image
        end
        os_images
      end
    end
  end
end


class Azure::VirtualMachineImageManagement::VirtualMachineImageManagementService
  alias_method :list_public_virtual_machine_images, :list_virtual_machine_images

  def list_virtual_machine_images
    list_public_virtual_machine_images + list_user_virtual_machine_images
  end

  def list_user_virtual_machine_images
    request_path = '/services/vmimages'
    request = ::Azure::BaseManagement::ManagementHttpRequest.new(:get, request_path, nil)
    response = request.call
    Serialization.user_virtual_machine_images_from_xml(response)
  end
end

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
    {'id' => flavor_id}
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
    server = get(id_at_site, id_at_site)
    server ? server.destroy : false
  end
end

class Fog::Compute::Azure::Images
  alias_method :all_orig, :all

  IMG_IDS = [
      'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20150123-en-us-30GB',
      'b9013ee6-c719-4865-bfb8-ca1fd3029b39-20150421-947991'
  ]

  def all(_filters = nil)
    # TODO: implement filters
    # Remove before flight!

    all_orig.select{ |tmpl| IMG_IDS.include? tmpl.name }
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

# azure vm create -g atmosphere -p TomekiPiotrek2015! --json -e -z ExtraSmall tbcli-test Ubuntu_14.04.1_LTS_Apach2

# ============= END AZURE ==========