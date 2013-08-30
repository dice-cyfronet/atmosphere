class CreatePortMappingProperties < ActiveRecord::Migration
  def change
    create_table :port_mapping_properties do |t|
      t.string :key,                 null: false
      t.string :value,               null: false

      t.references :port_mapping_template
      t.references :compute_site

      t.timestamps
    end

    add_foreign_key :port_mapping_properties, :port_mapping_templates
    add_foreign_key :port_mapping_properties, :compute_sites

  end
end
