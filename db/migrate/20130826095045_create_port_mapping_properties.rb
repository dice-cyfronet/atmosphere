class CreatePortMappingProperties < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_port_mapping_properties do |t|
      t.string :key,                 null: false
      t.string :value,               null: false

      t.references :port_mapping_template
      t.references :compute_site

      t.timestamps
    end

    add_foreign_key :atmosphere_port_mapping_properties,
                    :atmosphere_port_mapping_templates,
                    column: 'port_mapping_template_id'

    add_foreign_key :atmosphere_port_mapping_properties,
                    :atmosphere_compute_sites,
                    column: 'compute_site_id'

  end
end
