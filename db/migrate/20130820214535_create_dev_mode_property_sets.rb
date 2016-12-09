class CreateDevModePropertySets < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_dev_mode_property_sets do |t|
      t.string  :name,                  null: false
      t.text    :description
      t.boolean :shared,                null: false, default: false
      t.boolean :scalable,              null: false, default: false

      t.float   :preference_cpu
      t.integer :preference_memory
      t.integer :preference_disk

      t.references :appliance,          null: false

      t.timestamps
    end

    add_foreign_key :atmosphere_dev_mode_property_sets,
                    :atmosphere_appliances,
                    column: 'appliance_id'
  end
end
