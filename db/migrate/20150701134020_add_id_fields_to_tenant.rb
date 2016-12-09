class AddIdFieldsToTenant < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_tenants, :network_id, :string
  end
end
