# == Schema Information
#
# Table name: billing_logs
#
#  id            :integer          not null, primary key
#  timestamp     :datetime         not null
#  appliance     :string(255)      default("unknown appliance"), not null
#  fund          :string(255)      default("unknown fund"), not null
#  actor         :string(255)      default("unknown billing actor"), not null
#  message       :string(255)      default("appliance prolongation"), not null
#  currency      :string(255)      default("EUR"), not null
#  amount_billed :integer          default(0), not null
#  user_id       :integer
#

# This table constitutes a relational log for the billing service
# Each controller and service which performs billing operations should write to this log
# This is a standalone class - it is not directly related to any other classes in the model; instead it preserves searchable data in the form of strings
# Note: the 'actor' column should be used to specify which controller/service added the given log entry.

class BillingLog < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :appliance, :fund, :actor
  validates_numericality_of :amount_billed

end
