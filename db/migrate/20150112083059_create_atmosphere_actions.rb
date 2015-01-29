class CreateAtmosphereActions < ActiveRecord::Migration
  def change
    create_table :atmosphere_actions do |t|
      t.string :type
      t.references :appliance, index: true
      t.timestamps
    end
  end
end
