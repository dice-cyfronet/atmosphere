class AddSecuredToEndpoint < ActiveRecord::Migration[4.2]
  def change
    change_table :atmosphere_endpoints do |t|
      t.column :secured, :boolean, null: false, default: false
    end
  end
end
