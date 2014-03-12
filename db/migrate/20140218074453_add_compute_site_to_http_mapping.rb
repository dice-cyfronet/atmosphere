class AddComputeSiteToHttpMapping < ActiveRecord::Migration
  def up
    puts "Deleting all old http mappings"
    HttpMapping.delete_all

    change_table :http_mappings do |t|
      t.references :compute_site, null: false
    end
    add_foreign_key :http_mappings, :compute_sites

    puts "Updating http mappings for all existing appliances"
    Appliance.all.each do |appl|
      Proxy::ApplianceProxyUpdater.new(appl).update
    end
  end

  def down
    remove_foreign_key :http_mappings, :compute_sites
    remove_column :http_mappings, :compute_site_id
  end
end
