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
  # include ActiveModel::Dirty
  # define_attribute_methods :ip

  has_many :saved_templates, class_name: 'VirtualMachineTemplate'
  has_many :port_mappings, dependent: :destroy
  belongs_to :source_template, class_name: 'VirtualMachineTemplate', foreign_key: 'virtual_machine_template_id'
  belongs_to :compute_site
  has_and_belongs_to_many :appliances
  validates_presence_of :name, :virtual_machine_template_id
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id

  before_create :instantiate_vm, unless: :id_at_site
  after_destroy :generate_proxy_conf
  after_destroy :remove_from_dnat, if: :ip?
  after_save :generate_proxy_conf, if: :ip_changed?
  after_update :update_dnat, if: :ip_changed?

  def uuid
    "#{compute_site.site_id}-vm-#{id_at_site}"
  end

  def reboot
    cloud_client = VirtualMachine.get_cloud_client_for_site(compute_site.site_id)
    cloud_client.reboot_server id_at_site
    state = :booting
    save
  end

  def appliance_type
    return source_template.appliance_type if source_template
    return nil
  end

  def destroy(delete_in_cloud = true)
    delete_in_cloud if delete_in_cloud
    super()
  end

  private

  def instantiate_vm
    logger.info 'Instantiating'
    vm_tmpl = VirtualMachineTemplate.find(virtual_machine_template_id)
    cloud_client = vm_tmpl.compute_site.cloud_client
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
    cloud_client = compute_site.cloud_client
    cloud_client.servers.destroy(id_at_site)
  end

  def generate_proxy_conf
    ProxyConfWorker.new.perform(self.compute_site.id)
  end

  def update_dnat
    if previous_changes.include? :ip and not previous_changes[:ip].first.blank?
    end
    WranglerRegistrarWorker.new.async_perform(id) if ip?
  end

  def remove_from_dnat
    WranglerEraserWorker.new.async_perform(vm_id: id)
  end

end
