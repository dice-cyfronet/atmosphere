class CreateApplianceSets < ActiveRecord::Migration
  def change
    create_table :appliance_sets do |t|
      #t.string  :name,                   null: false
      t.string  :context_id,             null: false
      t.integer :priority,               null: false, default: 50
      t.string  :appliance_set_type,     null: false, default: 'development'

      t.references :user,                null: false, index: true

      # TODO we need reference to VirtualMachines here

      t.timestamps
    end

    add_index :appliance_sets, :context_id, unique: true
  end
end
