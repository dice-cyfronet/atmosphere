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
  include Cloud
  belongs_to :source_vm, class_name: 'VirtualMachine', foreign_key: 'virtual_machine_id'
  has_many :instances, class_name: 'VirtualMachine'
  belongs_to :compute_site
  belongs_to :appliance_type
  #validates_presence_of :id_at_site, :name, :state, :compute_site_id
  #validates_uniqueness_of :id_at_site, :scope => :compute_site_id

  before_create :save_template_in_cloud
  before_destroy :delete_in_cloud
  def uuid
    "#{compute_site.site_id}-tmpl-#{id_at_site}"
  end

  private

  def save_template_in_cloud
    logger.info "Saving template"
    vm = VirtualMachine.find(virtual_machine_id)
    cs = vm.compute_site
    cloud_client = VirtualMachineTemplate.get_cloud_client_for_site(cs.site_id)
    result = cloud_client.create_image(vm.id_at_site, name || vm.name)
    if result.status == 200
      id_at_site = result.body['image']['id']
      logger.info "Created template #{id_at_site} in site #{cs.site_id}"
      self[:id_at_site] = id_at_site
    else
      logger.error "Error creating template #{result}"
    end
    self.compute_site = cs
    self.name = vm.name unless self.name
    self.state = :saving
    #self.appliance_type = vm.appliance_type
  end

  def delete_in_cloud
    logger.info "Deleting template #{uuid}"
    cloud_client = VirtualMachineTemplate.get_cloud_client_for_site(self.compute_site.site_id)
    cloud_client.images.destroy self.id_at_site
    logger.info "Destroyed template #{uuid}"
  end

end
