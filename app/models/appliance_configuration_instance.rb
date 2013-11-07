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

class ApplianceConfigurationInstance < ActiveRecord::Base
  include ParamsRegexpable

  belongs_to :appliance_configuration_template

  has_many :appliances

  def create_payload(raw_payload, params = {})
    self.payload = raw_payload.gsub(/#{param_regexp}/) do |param_name|
          params[param_name[param_range]]
        end
  end
end
