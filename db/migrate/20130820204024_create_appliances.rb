class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :appliances do |t|
      t.references :appliance_set
      t.references :appliance_type

      t.timestamps
    end
  end
end
