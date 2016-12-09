class CreateAtmosphereActions < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_actions do |t|
      t.string :action_type
      t.references :appliance, index: true
      t.datetime :created_at
    end
  end
end
