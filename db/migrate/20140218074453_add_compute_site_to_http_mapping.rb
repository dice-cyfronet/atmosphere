class AddComputeSiteToHttpMapping < ActiveRecord::Migration[4.2]
  def up
    puts "Deleting all old http mappings"
    Atmosphere::HttpMapping.delete_all

    change_table :atmosphere_http_mappings do |t|
      t.references :compute_site, null: false
    end

    add_foreign_key :atmosphere_http_mappings,
                    :atmosphere_compute_sites,
                    column: 'compute_site_id'

    puts "Updating http mappings for all existing appliances"
    Atmosphere::Appliance.all.each do |appl|
      Atmosphere::Proxy::ApplianceProxyUpdater.new(appl).update
    end
  end

  def down
    remove_foreign_key :atmosphere_http_mappings,
                       :atmosphere_compute_sites,
                       column: 'compute_site_id'

    remove_column :atmosphere_http_mappings, :compute_site_id
  end
end
