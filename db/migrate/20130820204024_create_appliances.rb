class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :appliances do |t|
      t.references :appliance_set,                null: false
      t.references :appliance_type,               null: false

      t.timestamps
    end

    add_foreign_key :appliances, :appliance_sets
    add_foreign_key :appliances, :appliance_types
  end
end
