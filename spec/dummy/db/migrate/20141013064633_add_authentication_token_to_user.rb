class AddAuthenticationTokenToUser < ActiveRecord::Migration
  def change
    add_column :atmosphere_users, :authentication_token, :string

    add_index :atmosphere_users,
              :authentication_token,
              unique: true
  end
end
