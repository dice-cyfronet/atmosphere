# == Schema Information
#
# Table name: appliance_compute_sites
#
#  id              :integer          not null, primary key
#  appliance_id    :integer
#  compute_site_id :integer
#

# ApplianceTenants provide a m:n link between appliances and tenants
module Atmosphere
  class ApplianceTenant < ActiveRecord::Base
    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :tenant,
    class_name: 'Atmosphere::Tenant'
  end
end
