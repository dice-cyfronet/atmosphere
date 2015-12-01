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
    include Atmosphere::VirtualMachineTemplateExt
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

    has_many :migration_job,
             dependent: :destroy,
             class_name: 'Atmosphere::MigrationJob'

    has_and_belongs_to_many :tenants,
      class_name: 'Atmosphere::Tenant',
      join_table: 'atmosphere_virtual_machine_template_tenants'

    belongs_to :appliance_type,
               class_name: 'Atmosphere::ApplianceType'

    validates :id_at_site,
              presence: true

    validates :state,
              presence: true,
              inclusion: ALLOWED_STATES

    validates :architecture,
              inclusion: %w(i386 x86_64)

    validate :cant_have_vmt_not_bound_to_any_tenants

    enumerize :state, in: ALLOWED_STATES

    before_save :set_version, if: :update_version?
    before_update :release_source_vm, if: :saved?
    after_update :destroy_source_vm, if: :saved?
    before_destroy :cant_destroy_non_managed_vmt
    after_destroy :destroy_source_vm

    scope :def_order, -> { order(:name) }

    scope :unassigned, -> { where(appliance_type_id: nil) }

    scope :active, -> { where(state: 'active') }

    scope :on_active_tenant, -> do
      joins(:tenants).
        where('atmosphere_tenants.active = ?', true)
    end

    scope :on_tenant, ->(t) do
      joins(:tenants).
        where('atmosphere_tenants.id = ?', t)
    end

    scope :on_tenant_with_src, ->(t_id, source_id) do
      joins(:tenants).
        where("atmosphere_tenants.tenant_id = ? AND
        id_at_site = ?", t_id, source_id)
    end

    def uuid
      if tenants.blank?
        "NOTENANT-tmpl-#{id_at_site}"
      else
        # Kinda hacky - assumes all vmt.tenants share the same site_id.
        "#{tenants.first.site_id}-tmpl-#{id_at_site}"
      end
    end

    def self.create_from_vm(virtual_machine, name = virtual_machine.name)
      name_with_timestamp = "#{name}/#{VirtualMachineTemplate.generate_timestamp}"
      tmpl_name = VirtualMachineTemplate.sanitize_tmpl_name(name_with_timestamp)
      t = virtual_machine.tenant

      id_at_site = t.cloud_client.
                   save_template(virtual_machine.id_at_site, tmpl_name)
      logger.info "Created template #{id_at_site}"

      vm_template = t.virtual_machine_templates.
                    find_or_initialize_by(id_at_site: id_at_site)

      vm_template.source_vm = virtual_machine
      vm_template.name = tmpl_name
      vm_template.managed_by_atmosphere = true
      vm_template.state = :saving
      vm_template.tenants = [t]
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
        (3 - l).times { tmpl_name << '_' }
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
      cloud_client.images.destroy id_at_site
      logger.info "Destroyed template #{uuid}"
    rescue Fog::Compute::OpenStack::NotFound, Fog::Compute::AWS::NotFound
      logger.warn("VMT with #{id_at_site} does not exist - continuing")
    end

    # Returns the hourly cost for this template assuming a given VM flavor
    def get_hourly_cost_for(flavor)
      incarnation = flavor.flavor_os_families.
                    detect { |fof| fof.os_family == appliance_type.os_family }
      incarnation && incarnation.hourly_cost
    end

    def export(tenant_id)
      destination_tenant = Tenant.find(tenant_id)
      if destination_tenant != tenant
        vmt_migrator = VmtMigrator.new(self, tenant,
                                       destination_tenant)
        vmt_migrator.execute
      end
    end

    private

    def self.generate_timestamp
      t = Time.now
      t.strftime("%d-%m-%Y/%H-%M-%S/#{t.usec}")
    end

    def release_source_vm
      self.source_vm = nil
    end

    def destroy_source_vm
      if virtual_machine_id_was
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

    def cant_destroy_non_managed_vmt
      errors.add :base, 'Virtual Machine Template is not managed by atmosphere' unless managed_by_atmosphere
    end

    def cant_have_vmt_not_bound_to_any_tenants
      errors.add :tenants, 'A Virtual Machine Template must be attached to at least one Tenant' unless tenants.present?
    end

    def cloud_client
      # WARNING! This will fail when the VMT is available on multiple tenants
      # The method should be overridden in any subproject which makes use of
      # tenants.
      if tenants.present?
        tenants.first.cloud_client
      end
    end

    def update_version?
      !version_changed? && appliance_type_id_changed?
    end

    def set_version
      self.version = appliance_type.version + 1 if appliance_type
    end
  end
end
