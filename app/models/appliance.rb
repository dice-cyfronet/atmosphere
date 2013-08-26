# == Schema Information
#
# Table name: appliances
#
#  id                                  :integer          not null, primary key
#  appliance_set_id                    :integer          not null
#  appliance_type_id                   :integer          not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  appliance_configuration_instance_id :integer          not null
#

class Appliance < ActiveRecord::Base

  belongs_to :appliance_set
  # This should also make sure the referenced entity exists; but we still should make a foreign key constraint in DB
  validates :appliance_set, presence: true

  belongs_to :appliance_type
  validates :appliance_type, presence: true

  belongs_to :appliance_configuration_instance
  validates :appliance_configuration_instance, presence: true

  has_many :http_mappings, dependent: :destroy

  has_and_belongs_to_many :virtual_machines

end
