class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :atmosphere_appliances do |t|
      t.references :appliance_set,                null: false
      t.references :appliance_type,               null: false
      t.references :user_key

      t.references :appliance_configuration_instance, null: false
      t.string :state, default: 'new', null: false
      t.string :name

      t.timestamps
    end

    add_foreign_key :atmosphere_appliances,
                    :atmosphere_appliance_sets,
                    column: 'appliance_set_id'

    add_foreign_key :atmosphere_appliances,
                    :atmosphere_appliance_types,
                    column: 'appliance_type_id'

    add_foreign_key :atmosphere_appliances,
                    :atmosphere_appliance_configuration_instances,
                    column: 'appliance_configuration_instance_id'

    add_foreign_key :atmosphere_appliances,
                    :atmosphere_user_keys,
                    column: 'user_key_id'
  end
end
