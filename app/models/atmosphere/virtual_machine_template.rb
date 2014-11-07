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
#  architecture          :string(255)      default("x86_64")
#

module Atmosphere
  class VirtualMachineTemplate < ActiveRecord::Base
    extend Enumerize
    include Childhoodable

    ALLOWED_STATES = [
      'active', 'deleted', 'error', 'saving',
      'queued', 'killed', 'pending_delete'
    ]

    belongs_to :source_vm,
      class_name: 'Atmosphere::VirtualMachine',
      foreign_key: 'virtual_machine_id'

    has_many :instances,
      dependent: :nullify,
      class_name: 'Atmosphere::VirtualMachine'

    belongs_to :compute_site,
      class_name: 'Atmosphere::ComputeSite'

    belongs_to :appliance_type,
      class_name: 'Atmosphere::ApplianceType'

    validates :compute_site_id,
              presence: true

    validates :compute_site_id,
              presence: true

    validates :id_at_site,
              presence: true,
              uniqueness: { scope: :compute_site_id }

    validates :state,
              presence: true,
              inclusion: ALLOWED_STATES

    validates :architecture,
              inclusion: %w(i386 x86_64)

    enumerize :state, in: ALLOWED_STATES

    before_update :release_source_vm, if: :saved?
    after_update :destroy_source_vm, if: :saved?
    before_destroy :cant_destroy_non_managed_vmt
    after_destroy :destroy_source_vm

    scope :def_order, -> { order(:name) }

    scope :unassigned, -> { where(appliance_type_id: nil) }

    scope :active, -> { where(state: 'active') }

    scope :on_active_cs, -> do
      joins(:compute_site)
        .where(atmosphere_compute_sites: { active: true })
    end

    scope :on_cs, ->(cs) { where(compute_site_id: cs) }


    def uuid
      "#{compute_site.site_id}-tmpl-#{id_at_site}"
    end

    def self.create_from_vm(virtual_machine, name = virtual_machine.name)
      name_with_timestamp = "#{name}/#{VirtualMachineTemplate.generate_timestamp}"
      tmpl_name = VirtualMachineTemplate.sanitize_tmpl_name(name_with_timestamp)
      cs = virtual_machine.compute_site

      id_at_site = cs.cloud_client
        .save_template(virtual_machine.id_at_site, tmpl_name)
      logger.info "Created template #{id_at_site}"

      vm_template = cs.virtual_machine_templates
        .find_or_initialize_by(id_at_site: id_at_site)

      vm_template.source_vm = virtual_machine
      vm_template.name = tmpl_name
      vm_template.managed_by_atmosphere = true
      vm_template.state = :saving
      virtual_machine.state = :saving

      begin
        vm_template.transaction do
          logger.info "Saving template #{vm_template}"
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

    def self.sanitize_tmpl_name(name)
      tmpl_name = name.dup
      l = tmpl_name.length
      if l < 3
        (3 - l).times{tmpl_name << '_'}
      elsif l > 128
        tmpl_name = tmpl_name[0, 128]
      end
      tmpl_name.gsub!(/[^([a-zA-Z]|\(|\)|\.|\-|\/|_|\d)]/, '_')
      tmpl_name
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

    def self.generate_timestamp
      t = Time.now;
      t.strftime("%d-%m-%Y/%H-%M-%S/#{t.usec}")
    end

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
end
