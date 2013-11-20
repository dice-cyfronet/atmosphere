# == Schema Information
#
# Table name: virtual_machine_templates
#
#  id                 :integer          not null, primary key
#  id_at_site         :string(255)      not null
#  name               :string(255)      not null
#  state              :string(255)      not null
#  compute_site_id    :integer          not null
#  virtual_machine_id :integer
#  appliance_type_id  :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class VirtualMachineTemplate < ActiveRecord::Base
  belongs_to :source_vm, class_name: 'VirtualMachine', foreign_key: 'virtual_machine_id'
  has_many :instances, class_name: 'VirtualMachine'
  belongs_to :compute_site
  belongs_to :appliance_type
  validates_presence_of :id_at_site, :name, :state, :compute_site_id
  validates_uniqueness_of :id_at_site, :scope => :compute_site_id

  def uuid
    "#{compute_site.site_id}-tmpl-#{id_at_site}"
  end

  def VirtualMachineTemplate.create_from_vm(virtual_machine, name=nil)
    vm_template = VirtualMachineTemplate.new(source_vm: virtual_machine, name: name|| virtual_machine.name)
    logger.info "Saving template #{vm_template}"
    cs = vm_template.source_vm.compute_site
    cloud_client = cs.cloud_client
    id_at_site = cloud_client.save_template(vm_template.source_vm.id_at_site, vm_template.name)
    logger.info "Created template #{id_at_site}"
    vm_template.id_at_site = id_at_site
    vm_template.compute_site = cs
    vm_template.state = :saving
    vm_template.save
    vm_template
  end

  def destroy(delete_in_cloud = true)
    delete_in_cloud if delete_in_cloud
    super()
  end

  private

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

  def delete_in_cloud
    logger.info "Deleting template #{uuid}"
    cloud_client = self.compute_site.cloud_client
    cloud_client.images.destroy self.id_at_site
    logger.info "Destroyed template #{uuid}"
  end

end
