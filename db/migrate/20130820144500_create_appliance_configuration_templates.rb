class CreateApplianceConfigurationTemplates < ActiveRecord::Migration
  def change
    create_table :atmosphere_appliance_configuration_templates do |t|
      t.string :name, null: false
      t.text :payload

      t.references :appliance_type, null: false

      t.timestamps
    end

    add_foreign_key :atmosphere_appliance_configuration_templates,
                    :atmosphere_appliance_types,
                    column: 'appliance_type_id',
                    name: 'atmo_config_templates_at_id_fk'

    add_index :atmosphere_appliance_configuration_templates,
              :appliance_type_id,
              name: 'atmo_act_appliance_type_id_ix'
  end
end
