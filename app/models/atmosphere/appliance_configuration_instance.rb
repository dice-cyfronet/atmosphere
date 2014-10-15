require 'atmosphere/params_regexpable'

# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer
#  created_at                          :datetime
#  updated_at                          :datetime
#

module Atmosphere
  class ApplianceConfigurationInstance < ActiveRecord::Base
    belongs_to :appliance_configuration_template,
      class_name: 'Atmosphere::ApplianceConfigurationTemplate'

    has_many :appliances,
      class_name: 'Atmosphere::Appliance'

    def self.get(config_template, params)
      instance_payload = ParamsRegexpable.filter(config_template.payload, params)

      find_instance(config_template, instance_payload) || new_instance(config_template, instance_payload)
    end

    private

    def self.find_instance(config_template, payload)
      config_template.appliance_configuration_instances.find_by(payload: payload)
    end

    def self.new_instance(config_template, payload)
      ApplianceConfigurationInstance.new(appliance_configuration_template: config_template, payload: payload)
    end
  end
end
