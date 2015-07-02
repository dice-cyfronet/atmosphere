class AddIdFieldsToTenant < ActiveRecord::Migration
  def change
    add_column :atmosphere_tenants, :network_id, :string
  end
end
