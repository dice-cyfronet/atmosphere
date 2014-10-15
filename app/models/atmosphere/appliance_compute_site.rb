# == Schema Information
#
# Table name: appliance_compute_sites
#
#  id              :integer          not null, primary key
#  appliance_id    :integer
#  compute_site_id :integer
#

# ApplianceComputeSites provide a m:n link between appliances and compute_sites.
module Atmosphere
  class ApplianceComputeSite < ActiveRecord::Base
    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :compute_site,
    class_name: 'Atmosphere::ComputeSite'
  end
end
