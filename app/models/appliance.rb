class Appliance < ActiveRecord::Base

  belongs_to :appliance_set
  # This should also make sure the referenced entity exists; but we still should make a foreign key constraint in DB
  validates :appliance_set, presence: true

  belongs_to :appliance_type
  validates :appliance_type, presence: true

end
