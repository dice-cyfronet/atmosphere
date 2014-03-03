class AddDefaultToUserFunds < ActiveRecord::Migration
  def change
    change_table :user_funds do |t|
      t.column :default, :boolean, default: false
    end
  end
end
