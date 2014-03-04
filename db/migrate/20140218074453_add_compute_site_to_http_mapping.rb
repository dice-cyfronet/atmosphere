class AddComputeSiteToHttpMapping < ActiveRecord::Migration
  def change
    change_table :http_mappings do |t|
      t.references :compute_site, null: true
    end

    puts "Setting compute site for existing http mappings"
    HttpMapping.all.each do |mapping|
      unless mapping.compute_site.blank?
        mapping.compute_site = mapping.appliance.virtual_machines.first.compute_site
        mapping.save!
      end
    end

    puts "Updating http mappings for all existing appliances"
    Appliance.all.each do |appl|
      ApplianceProxyUpdater.new(appl).update
    end

    add_foreign_key :http_mappings, :compute_sites
  end
end
