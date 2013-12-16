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

class ApplianceConfigurationTemplate < ActiveRecord::Base
  include ParamsRegexpable

  belongs_to :appliance_type

  validates_presence_of :name, :appliance_type
  validates_uniqueness_of :name, scope: :appliance_type

  has_many :appliance_configuration_instances, dependent: :nullify

  def parameters
    params = payload.blank? ? [] : payload.scan(/#{param_regexp}/).collect { |raw_param| raw_param[param_range] }
    params.delete(Air.config.mi_authentication_key)
    params
  end
end
