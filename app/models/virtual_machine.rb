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

  after_destroy :delete_dnat, if: :ip?
  after_update :regenerate_dnat, if: :ip_changed?
  before_destroy :cant_destroy_non_managed_vm

  scope :manageable, -> { where(managed_by_atmosphere: true) }
  scope :active, -> { where("state = 'active' AND ip IS NOT NULL") }

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

  private

  def perform_delete_in_cloud
    cloud_client = compute_site.cloud_client
    cloud_client.servers.destroy(id_at_site)
  end

  def cant_destroy_non_managed_vm
    errors.add :base, 'Virtual Machine is not managed by atmosphere' unless managed_by_atmosphere
  end
end
