# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#

class ApplianceConfigurationInstance < ActiveRecord::Base

  belongs_to :appliance_configuration_template

  has_many :appliances

  def create_payload(raw_payload, params = {})
    self.payload = raw_payload.gsub(/#{param_regexp}/) do |param_name|
          params[param_name[param_range]]
        end
  end

  private

  def param_range
    @param_range ||= eval(Air.config.config_param_range)
  end

  def param_regexp
    Air.config.config_param_regexp
  end
end
