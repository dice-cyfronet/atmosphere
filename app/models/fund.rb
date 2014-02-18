# == Schema Information
#
# Table name: funds
#
#  id                 :integer          not null, primary key
#  name               :string(255)      default("unnamed fund"), not null
#  balance            :integer          default(0), not null
#  currency_label     :string(255)      default("EUR"), not null
#  overdraft_limit    :integer          default(0), not null
#  termination_policy :string(255)      default("suspend"), not null
#

# Fund
# Added by PN on 2014-01-14
# This class stores information on monetary resources which are used to pay for continued operation of virtual machines
# Each user may belong to one or more fund and each fund may include multiple users
# Funds are linked to Appliances instead of VMs due to the fact that a single VM may be shared by multiple Appliances
# (and therefore multiple users), in which case all owners "chip in" to enable continued operation of the VM.

class Fund < ActiveRecord::Base

  has_many :appliances
  has_many :users, through: :user_funds
  has_many :user_funds, dependent: :destroy

  validates_presence_of :name
  validates_numericality_of :balance
  validates_numericality_of :overdraft_limit, less_than_or_equal_to: 0
  validates :termination_policy, inclusion: {in: ["delete", "suspend", "no_action"]}

end
