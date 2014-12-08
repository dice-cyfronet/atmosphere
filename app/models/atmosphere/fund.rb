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
# Funds are also linked to ComputeSites and may only be used to pay for VMs which belong to their respective ComputeSites.
module Atmosphere
  class Fund < ActiveRecord::Base
    extend Enumerize

    has_many :appliances,
        class_name: 'Atmosphere::Appliance'

    has_many :users,
        through: :user_funds,
        class_name: 'Atmosphere::User'

    has_many :user_funds,
        dependent: :destroy,
        class_name: 'Atmosphere::UserFund'

    has_many :compute_sites,
        through: :compute_site_funds,
        class_name: 'Atmosphere::ComputeSite'

    has_many :compute_site_funds,
        dependent: :destroy,
        class_name: 'Atmosphere::ComputeSiteFund'

    validates :name,
              presence: true

    validates :balance,
              numericality: true

    validates :overdraft_limit,
              numericality: { less_than_or_equal_to: 0 }

    validates :termination_policy,
              inclusion: {in: ["delete", "suspend", "no_action"]}
    enumerize :termination_policy, in: [:delete, :suspend, :no_action], predicates: true

  end
end
