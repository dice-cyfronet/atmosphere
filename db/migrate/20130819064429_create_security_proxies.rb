class CreateSecurityProxies < ActiveRecord::Migration
  def change
    create_table :security_proxies do |t|
      t.string :name
      t.text :payload

      t.timestamps
    end

    create_table :security_proxies_users do |t|
      t.belongs_to :user
      t.belongs_to :security_proxy
    end

    add_index :security_proxies, :name, unique: true
  end
end
