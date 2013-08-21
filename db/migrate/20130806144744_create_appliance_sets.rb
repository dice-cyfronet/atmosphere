class CreateApplianceSets < ActiveRecord::Migration
  def change
    create_table :appliance_sets do |t|
      t.string  :name,                   null: true
      t.string  :context_id,             null: false
      t.integer :priority,               null: false, default: 50
      t.string  :appliance_set_type,     null: false, default: :development

      t.references :user,                null: false, index: true

      t.timestamps
    end

    add_index :appliance_sets, :context_id, unique: true
    add_foreign_key :appliance_sets, :users
  end
end
