class CreateSecurityPolicies < ActiveRecord::Migration
  def change
    create_table :security_policies do |t|
      t.string :name
      t.text :payload

      t.timestamps
    end

    create_table :security_policies_users do |t|
      t.belongs_to :user
      t.belongs_to :security_policy
    end

    add_index :security_policies, :name, unique: true
  end
end
