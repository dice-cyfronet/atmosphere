# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  managed_by_atmosphere       :boolean          default(FALSE), not null
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#  virtual_machine_flavor_id   :integer
#

require "zabbix"

class VirtualMachine < ActiveRecord::Base
  extend Enumerize

  has_many :saved_templates, class_name: 'VirtualMachineTemplate', dependent: :nullify
  has_many :port_mappings, dependent: :delete_all
  belongs_to :source_template, class_name: 'VirtualMachineTemplate', foreign_key: 'virtual_machine_template_id'
  belongs_to :compute_site
  belongs_to :virtual_machine_flavor
  has_many :appliances, through: :deployments, dependent: :destroy
  has_many :deployments, dependent: :destroy
  validates_presence_of :name
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id
  enumerize :state, in: ['active', 'build', 'deleted', 'error', 'hard_reboot', 'password', 'reboot', 'rebuild', 'rescue', 'resize', 'revert_resize', 'shutoff', 'suspended', 'unknown', 'verify_resize', 'saving']
  validates :state, inclusion: %w(active build deleted error hard_reboot password reboot rebuild rescue resize revert_resize shutoff suspended unknown verify_resize saving)

  before_create :instantiate_vm, unless: :id_at_site
  after_destroy :generate_proxy_conf
  after_destroy :delete_dnat, if: :ip?
  after_save :generate_proxy_conf, if: :ip_changed?
  after_update :regenerate_dnat, if: :ip_changed?
  before_update :update_in_zabbix, if: :ip_changed?
  before_destroy :unregister_from_zabbix, if: :ip? && :zabbix_host_id?
  before_destroy :cant_destroy_non_managed_vm

  scope :manageable, -> { where(managed_by_atmosphere: true) }

  def uuid
    "#{compute_site.site_id}-vm-#{id_at_site}"
  end

  def reboot
    cloud_client = VirtualMachine.get_cloud_client_for_site(compute_site.site_id)
    cloud_client.reboot_server id_at_site
    state = :build
    save
  end

  def appliance_type
    return appliances.first.appliance_type if appliances.first
    return nil
  end

  def destroy(delete_in_cloud = true)
    saved_templates.each {|t| return if t.state == 'saving'}
    perform_delete_in_cloud if delete_in_cloud && managed_by_atmosphere
    super()
  end

  # Deletes all dnat redirections and then adds. Use it when IP of the vm has changed and existing redirection would not work any way.
  def regenerate_dnat
    if ip_was
      if delete_dnat
        port_mappings.delete_all
      end
    end
    add_dnat if ip
  end

  def add_dnat
    return unless ip?
    pmts = nil
    if (appliances.first and appliances.first.development?)
      pmts = appliances.first.dev_mode_property_set.port_mapping_templates
    else
      pmts = appliance_type.port_mapping_templates if appliance_type
    end
    return unless pmts
    already_added_mapping_tmpls = port_mappings ? port_mappings.collect {|m| m.port_mapping_template} : []
    to_add = pmts.select {|pmt| pmt.application_protocol.none?} - already_added_mapping_tmpls
    compute_site.dnat_client.add_dnat_for_vm(self, to_add).each {|added_mapping_attrs| PortMapping.create(added_mapping_attrs)}
  end

  def delete_dnat
    compute_site.dnat_client.remove_dnat_for_vm(self)
  end

  def update_in_zabbix
    logger.info "Updating vm #{uuid} in Zabbix"
    if ip_was && zabbix_host_id
      unregister_from_zabbix
    end
    register_in_zabbix if ip
  end

  def register_in_zabbix
    logger.info "Registering vm #{uuid} in Zabbix"
    self[:zabbix_host_id] = Zabbix.register_host(uuid, ip)
  end

  def unregister_from_zabbix
    logger.info "Unregistering vm #{uuid} with zabbix host id #{zabbix_host_id} from Zabbix"
    Zabbix.unregister_host(self.zabbix_host_id)
    self[:zabbix_host_id] = nil
  end

  def current_load_metrics
      metrics=Zabbix.host_metrics(zabbix_host_id) if zabbix_host_id
      metrics.collect_last
  end

  def save_load_metrics(metrics)

  end

  private

  def instantiate_vm
    logger.info 'Instantiating'
    vm_tmpl = VirtualMachineTemplate.find(virtual_machine_template_id)
    cloud_client = vm_tmpl.compute_site.cloud_client
    flavor_id = (virtual_machine_flavor.flavor_name if virtual_machine_flavor) || '1'
    servers_params = {flavor_ref: flavor_id, flavor_id: flavor_id, name: name, image_ref: vm_tmpl.id_at_site, image_id: vm_tmpl.id_at_site}
    if vm_tmpl.compute_site.technology == 'aws'
      servers_params[:groups] = ['mniec_permit_all']
    end
    unless appliances.blank?
      user_data = appliances.first.appliance_configuration_instance.payload
      servers_params[:user_data] = user_data if user_data
      user_key = appliances.first.user_key
      if user_key
        user_key.import_to_cloud(vm_tmpl.compute_site)
        servers_params[:key_name] = user_key.id_at_site
      end
    end
    logger.debug "Params of instantiating server #{servers_params}"
    server = cloud_client.servers.create(servers_params)
    logger.info "instantiated #{server.id}"
    self[:id_at_site] = server.id
    self[:compute_site_id] = vm_tmpl.compute_site_id
    self[:state] = :build
    self[:managed_by_atmosphere] = true
  end

  def perform_delete_in_cloud
    cloud_client = compute_site.cloud_client
    cloud_client.servers.destroy(id_at_site)
  end

  def generate_proxy_conf
    ProxyConfWorker.regeneration_required(compute_site)
  end

  def cant_destroy_non_managed_vm
    errors.add :base, 'Virtual Machine is not managed by atmosphere' unless managed_by_atmosphere
  end
end
