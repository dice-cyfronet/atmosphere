class CreatePortMappingTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_port_mapping_templates do |t|
      t.string :transport_protocol,             null: false, default: 'tcp'
      t.string :application_protocol,           null: false, default: 'http_https'
      t.string :service_name,                   null: false
      t.integer :target_port,                   null: false

      t.references :appliance_type,             null: true
      t.references :dev_mode_property_set,      null: true

      t.timestamps
    end

    add_foreign_key :atmosphere_port_mapping_templates,
                    :atmosphere_appliance_types,
                    column: 'appliance_type_id'

    add_foreign_key :atmosphere_port_mapping_templates,
                    :atmosphere_dev_mode_property_sets,
                    column: 'dev_mode_property_set_id'
  end
end
