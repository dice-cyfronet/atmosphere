class CreateUserKeys < ActiveRecord::Migration
  def change
    create_table :user_keys do |t|
      t.string :name
      t.string :fingerprint
      t.text :public_key

      t.references :user,         null:false

      t.timestamps
    end
    add_foreign_key :user_keys, :users
  end
end
