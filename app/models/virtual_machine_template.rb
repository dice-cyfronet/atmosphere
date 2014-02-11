# == Schema Information
#
# Table name: virtual_machine_templates
#
#  id                    :integer          not null, primary key
#  id_at_site            :string(255)      not null
#  name                  :string(255)      not null
#  state                 :string(255)      not null
#  managed_by_atmosphere :boolean          default(FALSE), not null
#  compute_site_id       :integer          not null
#  virtual_machine_id    :integer
#  appliance_type_id     :integer
#  created_at            :datetime
#  updated_at            :datetime
#

class VirtualMachineTemplate < ActiveRecord::Base
  extend Enumerize

  belongs_to :source_vm, class_name: 'VirtualMachine', foreign_key: 'virtual_machine_id'
  has_many :instances, class_name: 'VirtualMachine', dependent: :nullify
  belongs_to :compute_site
  belongs_to :appliance_type
  validates_presence_of :id_at_site, :name, :state, :compute_site_id
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id
  enumerize :state, in: ['active', 'deleted', 'error', 'saving', 'queued', 'killed', 'pending_delete']
  validates :state, inclusion: %w(active deleted error saving queued killed pending_delete)
  before_update :release_source_vm, if: :saved?
  after_update :destroy_source_vm, if: :saved?
  before_destroy :cant_destroy_non_managed_vmt
  after_destroy :destroy_source_vm

  def uuid
    "#{compute_site.site_id}-tmpl-#{id_at_site}"
  end

  def self.create_from_vm(virtual_machine, name=nil)
    vm_template = VirtualMachineTemplate.new(source_vm: virtual_machine, name: name|| virtual_machine.name, managed_by_atmosphere: true)
    logger.info "Saving template #{vm_template}"
    cs = vm_template.source_vm.compute_site
    cloud_client = cs.cloud_client
    id_at_site = cloud_client.save_template(vm_template.source_vm.id_at_site, vm_template.name)
    logger.info "Created template #{id_at_site}"
    vm_template.id_at_site = id_at_site
    vm_template.compute_site = cs
    vm_template.state = :saving
    virtual_machine.state = :saving
    begin
      vm_template.transaction do
        vm_template.save!
        virtual_machine.save!
      end
    rescue
      logger.error $!
      vm_template.perform_delete_in_cloud
      raise $!
    end

    vm_template
  end

  def destroy(delete_in_cloud = true)
    perform_delete_in_cloud if delete_in_cloud && managed_by_atmosphere
    super()
  end

  def perform_delete_in_cloud
    logger.info "Deleting template #{uuid}"
    cloud_client = self.compute_site.cloud_client
    cloud_client.images.destroy self.id_at_site
    logger.info "Destroyed template #{uuid}"
  end

  private

  def release_source_vm
    self.source_vm = nil
  end

  def destroy_source_vm
    if  virtual_machine_id_was
      vm = VirtualMachine.find(virtual_machine_id_was)
      vm.destroy if vm.appliances.blank?
    end
  end

  def saved?
    state_changed? && !saving?
  end

  def saving?
    state == 'saving' || state == :saving
  end

  def save_template_in_cloud
    logger.info "Saving template"
    cs = source_vm.compute_site
    cloud_client = cs.cloud_client
    id_at_site = cloud_client.save_template(source_vm.id_at_site, name)
    logger.info "Created template #{id_at_site}"
    self.id_at_site = id_at_site
    self.compute_site = cs
    self.state = :saving
    #self.appliance_type = vm.appliance_type
  end

  def cant_destroy_non_managed_vmt
    errors.add :base, 'Virtual Machine Template is not managed by atmosphere' unless managed_by_atmosphere
  end
end
