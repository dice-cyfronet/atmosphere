# ApplianceComputeSites provide a m:n link between appliances and compute_sites.
class ApplianceComputeSite < ActiveRecord::Base
  belongs_to :appliance
  belongs_to :compute_site
end
