# This table constitutes a relational log for the billing service
# Each controller and service which performs billing operations should write to this log
# This is a standalone class - it is not directly related to any other classes in the model; instead it preserves searchable data in the form of strings
# Note: the 'actor' column should be used to specify which controller/service added the given log entry.

class BillingLog < ActiveRecord::Base

  validates_presence_of :username, :appliance, :cloud_site, :fund, :actor
  validates_numericality_of :amount_billed

end
