# == Schema Information
#
# Table name: deployments
#
#  id                 :integer          not null, primary key
#  virtual_machine_id :integer
#  appliance_id       :integer
#

# Deployments provide a m:n link between appliances and virtual machines.
module Atmosphere
  class Deployment < ActiveRecord::Base
    extend Enumerize
    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :virtual_machine,
      class_name: 'Atmosphere::VirtualMachine'

    validates :billing_state, presence: true

    enumerize :billing_state, in: ["initial", "prepaid", "expired", "error"], predicates: true

    after_create :initial_billing

    def initial_billing
      # This method sets billing details for a newly created deployment
      self.prepaid_until = Time.now.utc
      self.billing_state = "expired"
    end

  end
end