class AddBillingFieldsToAppliances < ActiveRecord::Migration[4.2]
  def change
    change_table :atmosphere_appliances do |t|
      # The following line does not work because Rails does not support CURRENT_TIMESTAMP as default value in a migration script.
      # As such, prepaid_until must be declared by a direct SQL call to the database (see below).
      # This is rather sad, but yeah - ORMs. Whatcha gonna do. :(
      # See below for SQL.
      # t.column :prepaid_until, :datetime, null:false # Indicates how long the user is authorized to access this appliance.
      t.column :amount_billed, :integer, null: false, default: 0 # Total amount billed for this appliance
      t.column :billing_state, :string, null:false, default:"prepaid"
    end

    # Time for some good old-fashioned SQL because the Rails ORM model is too constraining to support this...
    execute "ALTER TABLE atmosphere_appliances ADD COLUMN prepaid_until TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP"

  end
end
