# == Schema Information
#
# Table name: appliance_types
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  description        :text
#  shared             :boolean          default(FALSE), not null
#  scalable           :boolean          default(FALSE), not null
#  visible_to         :string(255)      default("owner"), not null
#  preference_cpu     :float
#  preference_memory  :integer
#  preference_disk    :integer
#  security_proxy_id  :integer
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  metadata_global_id :string(255)
#
module Atmosphere
  class ApplianceType < ActiveRecord::Base
    include Atmosphere::ApplianceTypeExt
    extend Enumerize

    belongs_to :author,
               class_name: 'Atmosphere::User',
               foreign_key: 'user_id'

    belongs_to :os_family,
               class_name: 'Atmosphere::OSFamily'

    has_many :appliances,
             dependent: :destroy,
             class_name: 'Atmosphere::Appliance'

    has_many :port_mapping_templates,
             dependent: :destroy,
             class_name: 'Atmosphere::PortMappingTemplate'

    has_many :appliance_configuration_templates,
             dependent: :destroy,
             class_name: 'Atmosphere::ApplianceConfigurationTemplate'

    has_many :virtual_machine_templates,
             dependent: :nullify,
             class_name: 'Atmosphere::VirtualMachineTemplate'

    has_many :migration_job,
             dependent: :nullify,
             class_name: 'Atmosphere::MigrationJob'

    # Required for API (returning all tenants on which a given
    # AT can be deployed). By allowed tenant we understan active tenant
    # with VMT installed.
    has_many :tenants,
             -> { where(atmosphere_tenants: { active: true }).uniq },
             through: :virtual_machine_templates,
             class_name: 'Atmosphere::Tenant'

    validates :visible_to, presence: true

    validates :name,
              uniqueness: true,
              presence: true

    validates :visible_to,
              inclusion: %w(owner developer all)

    validates :shared,
              inclusion: [true, false]

    validates :scalable,
              inclusion: [true, false]

    validates :preference_memory,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true
              }

    validates :preference_disk,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true
              }

    validates :preference_cpu,
              numericality: {
                greater_than_or_equal_to: 0.0,
                allow_nil: true
              }

    validates :os_family, presence: true

    enumerize :visible_to, in: [:owner, :developer, :all]

    scope :def_order, -> { order(:name) }

    scope :active, -> { with_vmt_state(:active) }
    scope :inactive, -> { without_vmt_state(:active) }

    scope :saving, -> { with_vmt_state(:saving) }
    scope :not_saving, -> { without_vmt_state(:saving) }

    scope :with_vmt_state, ->(state) do
      joins(:virtual_machine_templates).
        where(atmosphere_virtual_machine_templates: { state: state }).uniq
    end

    scope :without_vmt_state, ->(state) do
      query = <<-SQL
        id NOT IN (
          SELECT appliance_type_id
            FROM atmosphere_virtual_machine_templates
            WHERE state = ?)
      SQL

      where(query, state)
    end

    scope :with_vmt, ->(t_tenant_id, vmt_id_at_site) do
      joins(virtual_machine_templates: :tenants).
        where(
          atmosphere_tenants: { tenant_id: t_tenant_id },
          atmosphere_virtual_machine_templates: { id_at_site: vmt_id_at_site }
        )
    end

    around_destroy :delete_vmts, prepend: true

    def destroy(force = false)
      if !force && has_dependencies?
        errors.add :base, "#{name} cannot be destroyed because other users have running instances of this application."
        return false
      end
      # Parentheses required NOT to pass 'force' as an argument (not needed in
      # Base.destroy)
      super()
    end

    def has_dependencies?
      # TODO temporary removing this check for PN request
      # virtual_machine_templates.present? or
      appliances.present?
    end

    def author_name
      author ? author.login : 'anonymous'
    end

    def self.create_from(appliance, overwrite = {})
      at = ApplianceType.new appliance_type_attributes(appliance, overwrite)
      PmtCopier.new(appliance.dev_mode_property_set).execute.each do |pmt|
        pmt.appliance_type = at
        at.port_mapping_templates << pmt
      end if appliance && appliance.dev_mode_property_set
      ActCopier.new(appliance.appliance_type).execute.each do |act|
        act.appliance_type = at
        at.appliance_configuration_templates << act
      end if appliance

      at
    end

    def publishable?
      visible_to.developer? || visible_to.all?
    end

    def development?
      visible_to.developer?
    end

    def appropriate_for?(appliance_set)
      case visible_to.to_sym
      when :owner then appliance_set.user == author
      when :developer then appliance_set.appliance_set_type.development?
      else true
      end
    end

    def version
      virtual_machine_templates.maximum(:version) || 0
    end

    private

    def self.appliance_type_attributes(appliance, overwrite)
      if appliance && appliance.dev_mode_property_set
        params = appliance.dev_mode_property_set.attributes
        %w(id created_at updated_at appliance_id).
          each { |el| params.delete(el) }
      end
      params ||= {}

      overwrite_dup = overwrite.dup
      overwrite_dup.delete(:appliance_id)
      params.merge! overwrite_dup

      params
    end

    def delete_vmts
      vmts = virtual_machine_templates.to_a
      yield
      vmts.each(&:destroy)
    end
  end
end
