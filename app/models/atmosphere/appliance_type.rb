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
    self.table_name = 'appliance_types'
    include Atmosphere::ApplianceTypeExt

    belongs_to :author,
      class_name: 'Atmosphere::User',
      foreign_key: 'user_id'

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
      class_name: 'Atmosphere::VirtualMachineTemplate'

    # Required for API (returning all compute sites on which a given
    # AT can be deployed). By allowed compute site we understan active compute site
    # with VMT installed.
    has_many :compute_sites,
      -> { where(compute_sites: {active: true}).uniq },
      through: :virtual_machine_templates,
      class_name: 'Atmosphere::ComputeSite'

    extend Enumerize
    enumerize :visible_to, in: [:owner, :developer, :all]

    validates_presence_of :name, :visible_to
    validates_uniqueness_of :name

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

    scope :def_order, -> { order(:name) }
    scope :active, -> { joins(:virtual_machine_templates).where(virtual_machine_templates: {state: :active}).uniq }
    scope :inactive, -> { where("id NOT IN (SELECT appliance_type_id FROM virtual_machine_templates WHERE state = 'active')") }

    scope :with_vmt, ->(cs_site_id, vmt_id_at_site) do
      joins(virtual_machine_templates: :compute_site).
      where(
        compute_sites: { site_id: cs_site_id },
        virtual_machine_templates: { id_at_site: vmt_id_at_site }
      )
    end

    around_destroy :delete_vmts


    def destroy(force = false)
      if !force and has_dependencies?
        errors.add :base, "#{name} cannot be destroyed because other users have running instances of this application."
        return false
      end
      super()  # Parentheses required NOT to pass 'force' as an argument (not needed in Base.destroy)
    end

    def has_dependencies?
      # TODO temporary removing this check for PN request
      #virtual_machine_templates.present? or
      appliances.present?
    end

    def author_name
      author ? author.login : 'anonymous'
    end

    def self.create_from(appliance, overwrite = {})
      at = ApplianceType.new appliance_type_attributes(appliance, overwrite)
      PmtCopier.copy(appliance.dev_mode_property_set).each do |pmt|
        pmt.appliance_type = at
        at.port_mapping_templates << pmt
      end if appliance and appliance.dev_mode_property_set
      ActCopier.copy(appliance.appliance_type).each do |act|
        act.appliance_type = at
        at.appliance_configuration_templates << act
      end if appliance

      at
    end

    def publishable?
      visible_to.developer? or visible_to.all?
    end

    def development?
      visible_to.developer?
    end

    private

    def self.appliance_type_attributes(appliance, overwrite)
      if appliance and appliance.dev_mode_property_set
        params = appliance.dev_mode_property_set.attributes
        %w(id created_at updated_at appliance_id).each { |el| params.delete(el) }
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