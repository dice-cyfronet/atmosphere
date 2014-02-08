class AddBillingFieldsToAppliances < ActiveRecord::Migration
  def change
    change_table :appliances do |t|
      t.datetime :prepaid_until, :datetime, null:false # Indicates how long the user is authorized to access this appliance.
      t.column :amount_billed, :integer, null: false, default: 0 # Total amount billed for this appliance
      t.column :billing_state, :string, null:false, default:"prepaid"
    end
  end
end
