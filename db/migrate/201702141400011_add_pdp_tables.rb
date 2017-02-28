# This migration creates all the necessary schema models to ensure flavor and appliance type
# differentiation into OS families (typically Linux and Windows). This is necessary to facilitate
# proper billing where the price of a flavor depends on the installed OS.

class AddPdpTables < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_user_appliance_types do |t|
      t.belongs_to :user
      t.belongs_to :appliance_type

      t.string :role
    end
  end
end
