# == Schema Information
#
# Table name: appliance_sets
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  priority           :integer          default(50), not null
#  appliance_set_type :string(255)      default("workflow"), not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#
module Atmosphere
  class ApplianceSet < ActiveRecord::Base
    include Atmosphere::ApplianceSetExt
    extend Enumerize

    belongs_to :user,
               class_name: 'Atmosphere::User'

    has_many :appliances,
             class_name: 'Atmosphere::Appliance'

    validates :user, presence: true

    validates :priority,
              presence: true,
              numericality: { only_integer: true },
              inclusion: 1..100

    validates :appliance_set_type,
              presence: true,
              inclusion: %w(portal development workflow)

    validates :optimization_policy,
              inclusion: %w(manual),
              if: :optimization_policy

    validates :appliance_set_type,
              uniqueness: { scope: :user_id },
              if: 'appliance_set_type == "development" or appliance_set_type == "portal"'

    enumerize :appliance_set_type, in: [:portal, :development, :workflow]

    attr_readonly :appliance_set_type

    scope :with_vm, ->(virtual_machine) do
      joins(appliances: :virtual_machines).
        where(atmosphere_virtual_machines: { id: virtual_machine.id })
    end

    scope :clew_appliances, -> (appliance_set_type) do
      deps = if appliance_set_type.to_s == 'development'
               devel_clew_includes
             else
               prod_clew_includes
             end

      where(atmosphere_appliance_sets: {
              appliance_set_type: appliance_set_type
            }).includes(deps).references(deps)
    end

    def production?
      !appliance_set_type.development?
    end

    def development?
      appliance_set_type.development?
    end

    def self.devel_clew_includes
      basic_clew_includes.tap do |hsh|
        hsh[:appliances][:dev_mode_property_set] =
          { port_mapping_templates: :endpoints }
      end
    end

    def self.prod_clew_includes
      basic_clew_includes.tap do |hsh|
        hsh[:appliances][:appliance_type] =
          { port_mapping_templates: :endpoints }
      end
    end

    def self.basic_clew_includes
      {
        appliances: {
          deployments: {
            virtual_machine: [
              :port_mappings, :tenant, :virtual_machine_flavor
            ]
          },
          http_mappings: :port_mapping_template
        }
      }
    end
  end
end
