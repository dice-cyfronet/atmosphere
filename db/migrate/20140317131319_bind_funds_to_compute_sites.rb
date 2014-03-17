# Creates a linking table to bind Funds and ComputeSites in an m:n relationship
# Funds now only apply to specific compute_sites
class BindFundsToComputeSites < ActiveRecord::Migration
  def change
    create_table :compute_site_funds do |t|
      t.belongs_to :compute_site
      t.belongs_to :fund
    end
  end
end
