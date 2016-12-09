class AddStateExplanationToAppliance < ActiveRecord::Migration[4.2]
  def change
    change_table :atmosphere_appliances do |t|
      t.column :state_explanation, :string, null: true
    end
  end
end
