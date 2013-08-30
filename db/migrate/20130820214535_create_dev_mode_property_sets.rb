class CreateDevModePropertySets < ActiveRecord::Migration
  def change
    create_table :dev_mode_property_sets do |t|
      t.string  :name,                  null: false
      t.text    :description
      t.boolean :shared,                null: false, default: false
      t.boolean :scalable,              null: false, default: false

      t.float   :preference_cpu
      t.integer :preference_memory
      t.integer :preference_disk

      t.references :appliance,          null: false
      t.references :security_proxy,     null: true

      t.timestamps
    end

    add_foreign_key :dev_mode_property_sets, :appliances
    add_foreign_key :dev_mode_property_sets, :security_proxies
  end
end
