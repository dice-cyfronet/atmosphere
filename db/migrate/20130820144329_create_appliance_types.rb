class CreateApplianceTypes < ActiveRecord::Migration
  def change
    create_table :appliance_types do |t|

      t.string :name,                   null: false
      t.text :description
      t.boolean :shared,                null: false, default: false
      t.boolean :scalable,              null: false, default: false
      t.string :visibility,             null: false, default: 'under_development'

      # Incorporated from the old AppliancePreferences model
      t.float :preference_cpu
      t.integer :preference_memory
      t.integer :preference_disk

      t.references :security_proxy, null: true

      t.timestamps
    end

    add_index :appliance_types, :name, unique: true
  end
end
