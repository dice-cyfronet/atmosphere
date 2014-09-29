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
    self.table_name = 'appliance_compute_sites'

    belongs_to :appliance
    belongs_to :compute_site
  end
end
