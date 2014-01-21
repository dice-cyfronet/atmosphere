class CreateUserFunds < ActiveRecord::Migration
  def change
    create_table :user_funds do |t|
      t.belongs_to :user
      t.belongs_to :fund
    end
  end
end
