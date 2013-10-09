# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#

class VirtualMachine < ActiveRecord::Base
  include Cloud
  has_many :saved_templates, class_name: 'VirtualMachineTemplate'
  has_many :port_mappings, dependent: :destroy
  belongs_to :source_template, class_name: 'VirtualMachineTemplate', foreign_key: 'virtual_machine_template_id'
  belongs_to :compute_site
  has_and_belongs_to_many :appliances
  validates_presence_of :name, :virtual_machine_template_id
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id
  
  before_create :instantiate_vm
  before_destroy :delete_in_cloud

  def uuid
    "#{compute_site.site_id}-vm-#{id_at_site}"
  end

  def reboot
    cloud_client = VirtualMachine.get_cloud_client_for_site(compute_site.site_id)
    cloud_client.reboot_server id_at_site
    state = :booting
    save
  end

  private

  def instantiate_vm
    logger.info 'Instantiating'
    vm_tmpl = VirtualMachineTemplate.find(virtual_machine_template_id)
    cloud_client = VirtualMachine.get_cloud_client_for_site(vm_tmpl.compute_site.site_id)
    servers_params = {:flavor_ref => 1, :name => name, :image_ref => vm_tmpl.id_at_site, :key_name => 'tomek'}
    unless appliances.blank?
      user_data = appliances.first.appliance_configuration_instance.payload
      servers_params[:user_data] = user_data if user_data
    end
    server = cloud_client.servers.create(servers_params)
    logger.info "instantiated #{server.id}"
    self[:id_at_site] = server.id
    self[:compute_site_id] = vm_tmpl.compute_site_id
    self[:state] = :booting
  end

  def delete_in_cloud
    cloud_client = VirtualMachine.get_cloud_client_for_site(compute_site.site_id)
    cloud_client.servers.destroy(id_at_site)
  end

end
