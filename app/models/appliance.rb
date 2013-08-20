class Appliance < ActiveRecord::Base

  belongs_to :appliance_set
  belongs_to :appliance_type
end
