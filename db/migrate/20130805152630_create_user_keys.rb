class CreateUserKeys < ActiveRecord::Migration
  def change
    create_table :atmosphere_user_keys do |t|
      t.string :name,             null:false
      t.string :fingerprint,      null:false
      t.text :public_key,         null:false

      t.references :user,         null:false

      t.timestamps
    end
    add_foreign_key :atmosphere_user_keys,
                    :atmosphere_users,
                    column: 'user_id'

    add_index :atmosphere_user_keys,
              [:user_id, :name],
              unique: true
  end
end
