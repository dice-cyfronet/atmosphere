class AddComputeSiteToHttpMapping < ActiveRecord::Migration
  def change
    change_table :http_mappings do |t|
      t.references :compute_site, null: true
    end

    add_foreign_key :http_mappings, :compute_sites
  end
end
