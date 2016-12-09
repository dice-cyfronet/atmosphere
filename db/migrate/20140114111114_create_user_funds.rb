class CreateUserFunds < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_user_funds do |t|
      t.belongs_to :user
      t.belongs_to :fund
    end
  end
end
