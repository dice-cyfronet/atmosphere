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

    validates_presence_of :name, :appliance_type
    validates_uniqueness_of :name, scope: :appliance_type

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
      params.delete(Air.config.mi_authentication_key)
      params
    end
  end
end
