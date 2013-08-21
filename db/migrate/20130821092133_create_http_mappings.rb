class CreateHttpMappings < ActiveRecord::Migration
  def change
    create_table :http_mappings do |t|
      t.string :application_protocol, null: false, default: 'http'
      t.string :url, null: false, default: ''

      t.references :appliance
      t.references :port_mapping_template

      t.timestamps
    end

    add_foreign_key :http_mappings, :appliances
    add_foreign_key :http_mappings, :port_mapping_templates
  end
end
