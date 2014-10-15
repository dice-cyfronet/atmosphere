class CreateHttpMappings < ActiveRecord::Migration
  def change
    create_table :atmosphere_http_mappings do |t|
      t.string :application_protocol, null: false, default: 'http'
      t.string :url, null: false, default: ''

      t.references :appliance
      t.references :port_mapping_template

      t.timestamps
    end

    add_foreign_key :atmosphere_http_mappings,
                    :atmosphere_appliances,
                    column: 'appliance_id'

    add_foreign_key :atmosphere_http_mappings,
                    :atmosphere_port_mapping_templates,
                    column: 'port_mapping_template_id'
  end
end
