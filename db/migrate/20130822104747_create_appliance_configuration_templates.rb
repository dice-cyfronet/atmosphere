class CreateApplianceConfigurationTemplates < ActiveRecord::Migration
  def change
    create_table :appliance_configuration_templates do |t|
      t.string :name, null: false
      t.text :payload

      t.references :appliance_type, null: false, index: true

      t.timestamps
    end

    add_foreign_key :appliance_configuration_templates, :appliance_types
  end
end
