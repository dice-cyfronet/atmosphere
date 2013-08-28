class CreateEndpoints < ActiveRecord::Migration
  def change
    create_table :endpoints do |t|
      t.text :description
      # The below should force MySQL to use MEDIUMTEXT or LONGTEXT
      t.text :descriptor,                     limit: 16777215
      t.string :endpoint_type,                null: false, default: 'ws'

      t.references :port_mapping_template,    null: false

      t.timestamps
    end

    add_foreign_key :endpoints, :port_mapping_templates

  end
end
