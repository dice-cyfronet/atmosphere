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
    self.table_name = 'appliance_configuration_templates'

    belongs_to :appliance_type,
      class_name: 'Atmosphere::ApplianceType'

    validates_presence_of :name, :appliance_type
    validates_uniqueness_of :name, scope: :appliance_type

    has_many :appliance_configuration_instances, dependent: :nullify

    scope :with_config_instance, ->(config_instance) do
      ApplianceConfigurationTemplate.joins(
        :appliance_configuration_instances).where(
          appliance_configuration_instances: {id: config_instance}).first!
    end

    def parameters
      params = ParamsRegexpable.parameters(payload)
      params.delete(Air.config.mi_authentication_key)
      params
    end
  end
end
