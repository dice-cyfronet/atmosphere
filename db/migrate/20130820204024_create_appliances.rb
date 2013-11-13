class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :appliances do |t|
      t.references :appliance_set,                null: false
      t.references :appliance_type,               null: false
      t.references :user_key

      t.references :appliance_configuration_instance, null: false
      t.string :state, default: 'new', null: false

      t.timestamps
    end

    add_foreign_key :appliances, :appliance_sets
    add_foreign_key :appliances, :appliance_types
    add_foreign_key :appliances, :appliance_configuration_instances
    add_foreign_key :appliances, :user_keys
  end
end
