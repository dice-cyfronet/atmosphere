class CreatePortMappings < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_port_mappings do |t|
      t.string :public_ip,                    null: false
      t.integer :source_port,                 null: false

      t.references :port_mapping_template,    null: false
      t.references :virtual_machine,          null: false

      t.timestamps
    end

    add_foreign_key :atmosphere_port_mappings,
                    :atmosphere_port_mapping_templates,
                    column: 'port_mapping_template_id'

    add_foreign_key :atmosphere_port_mappings,
                    :atmosphere_virtual_machines,
                    column: 'virtual_machine_id'
  end
end
