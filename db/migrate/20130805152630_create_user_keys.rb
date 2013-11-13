class CreateUserKeys < ActiveRecord::Migration
  def change
    create_table :user_keys do |t|
      t.string :name,             null:false
      t.string :fingerprint,      null:false
      t.text :public_key,         null:false

      t.references :user,         null:false

      t.timestamps
    end
    add_foreign_key :user_keys, :users
    add_index :user_keys, [:user_id, :name], unique: true
  end
end
