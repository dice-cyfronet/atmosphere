# Creates a linking table to bind Funds and ComputeSites in an m:n relationship
# Funds now only apply to specific tenants
class BindFundsToComputeSites < ActiveRecord::Migration
  def change
    create_table :atmosphere_compute_site_funds do |t|
      t.belongs_to :compute_site
      t.belongs_to :fund
    end
  end
end
