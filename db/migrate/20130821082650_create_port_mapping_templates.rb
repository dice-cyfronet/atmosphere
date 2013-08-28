class CreatePortMappingTemplates < ActiveRecord::Migration
  def change
    create_table :port_mapping_templates do |t|
      t.string :transport_protocol,             null: false, default: 'tcp'
      t.string :application_protocol,           null: false, default: 'http_https'
      t.string :service_name,                   null: false
      t.integer :target_port,                   null: false

      t.references :appliance_type,             null: true
      t.references :dev_mode_property_set,      null: true

      t.timestamps
    end

    add_foreign_key :port_mapping_templates, :appliance_types
    add_foreign_key :port_mapping_templates, :dev_mode_property_sets
  end
end
