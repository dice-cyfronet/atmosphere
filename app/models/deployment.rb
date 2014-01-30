# == Schema Information
#
# Table name: deployments
#
#  id                 :integer          not null, primary key
#  virtual_machine_id :integer
#  appliance_id       :integer
#

# Deployments provide a m:n link between appliances and virtual machines.
class Deployment < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance
  belongs_to :virtual_machine

  before_destroy :generate_proxy_conf
  after_create :generate_proxy_conf if :vm_active?

  private

  def generate_proxy_conf
    ComputeSite.with_deployment(self).each do |cs|
      ProxyConfWorker.regeneration_required(cs)
    end
  end

  def vm_active?
    !virtual_machine.ip.blank?
  end
end
