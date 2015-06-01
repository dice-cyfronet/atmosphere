require 'azure/virtual_machine_image_management/serialization'
require 'azure/virtual_machine_management/serialization'
require 'azure/base_management/management_http_request'
require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'

require 'fog/azure/compute'
require 'fog/azure/models/compute/images'
require 'fog/azure/models/compute/server'
require 'fog/azure/models/compute/servers'

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
    puts "Params: #{params}"
    puts "Options: #{options}"
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
              if options[:static_virtual_network_ipaddress]
                xml.StaticVirtualNetworkIPAddress(
                  options[:static_virtual_network_ipaddress]
                )
              end
            end
          end
        end
        unless img_is_user_created
          xml.AvailabilitySetName options[:availability_set_name]
        end
        # Label does not seem to be required
        #xml.Label Base64.encode64(params[:vm_name]).strip

        if img_is_user_created
          xml.VMImageName params[:image]
          xml.ProvisionGuestAgent 'true'
        else
          xml.OSVirtualHardDisk do
            if img_is_user_created
              xml.MediaLink(
                "https://portalvhdswkd6qtd0zqkw9.blob.core.windows.net/vhds/"\
                "Ubuntu_14.04.1_LTS_Apach2-os-2015-04-21.vhd"
              )
            else
              xml.MediaLink(
                "http://#{options[:storage_account_name]}."\
                "blob.core.windows.net/vhds/"\
                "#{(Time.now.strftime('disk_%Y_%m_%d_%H_%M_%S_%L'))}.vhd"
              )
            end
            xml.SourceImageName params[:image] unless img_is_user_created
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
    img = img_svc.list_virtual_machine_images.select do |i|
      i.name == image_id
    end.first
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
    request = ::Azure::BaseManagement::ManagementHttpRequest.new(
      :get,
      request_path,
      nil
    )
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
