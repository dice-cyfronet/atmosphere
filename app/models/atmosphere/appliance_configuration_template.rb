require 'atmosphere/params_regexpable'

# == Schema Information
#
# Table name: appliance_configuration_templates
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  payload           :text
#  appliance_type_id :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#
module Atmosphere
  class ApplianceConfigurationTemplate < ActiveRecord::Base
    belongs_to :appliance_type,
      class_name: 'Atmosphere::ApplianceType'

    has_many :appliance_configuration_instances,
      class_name: 'Atmosphere::ApplianceConfigurationInstance',
      dependent: :nullify

    validates :name, presence: true
    validates :appliance_type, presence: true
    validates :name, uniqueness: { scope: :appliance_type }

    scope :with_config_instance, ->(config_instance) do
      joins(:appliance_configuration_instances)
        .where(
          atmosphere_appliance_configuration_instances: {
            id: config_instance
          }
        ).first!
    end

    def parameters
      params = ParamsRegexpable.parameters(payload)
      unless Atmosphere.delegation_initconf_key.blank?
        params.delete(Atmosphere.delegation_initconf_key)
      end

      params
    end
  end
end
