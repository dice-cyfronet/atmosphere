class CreateEndpoints < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_endpoints do |t|
      t.string :name,                         null: false
      t.text :description
      # The below should force MySQL to use MEDIUMTEXT or LONGTEXT
      t.text :descriptor,                     limit: 16777215
      t.string :endpoint_type,                null: false, default: 'ws'
      t.string :invocation_path,              null: false

      t.references :port_mapping_template,    null: false

      t.timestamps
    end

    add_foreign_key :atmosphere_endpoints,
                    :atmosphere_port_mapping_templates,
                    column: 'port_mapping_template_id'

  end
end
