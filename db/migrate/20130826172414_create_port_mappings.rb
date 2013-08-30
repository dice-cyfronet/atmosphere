class CreatePortMappings < ActiveRecord::Migration
  def change
    create_table :port_mappings do |t|
      t.string :public_ip,                    null: false
      t.integer :source_port,                 null: false

      t.references :port_mapping_template,    null: false
      t.references :virtual_machine,          null: false

      t.timestamps
    end

    add_foreign_key :port_mappings, :port_mapping_templates
    add_foreign_key :port_mappings, :virtual_machines
  end
end
