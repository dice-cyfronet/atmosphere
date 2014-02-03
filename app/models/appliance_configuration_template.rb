require 'params_regexpable'

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

  belongs_to :appliance_type

  validates_presence_of :name, :appliance_type
  validates_uniqueness_of :name, scope: :appliance_type

  has_many :appliance_configuration_instances, dependent: :nullify

  def parameters
    params = ParamsRegexpable.parameters(payload)
    params.delete(Air.config.mi_authentication_key)
    params
  end
end
