# This migration creates a table which will link users to appliance_types.
# The table is utilized by the local PDP and also stores the role of each
# relation.

class AddPdpTables < ActiveRecord::Migration
  def change
    create_table :atmosphere_user_appliance_types do |t|
      t.belongs_to :user
      t.belongs_to :appliance_type

      t.string :role
    end
  end
end
