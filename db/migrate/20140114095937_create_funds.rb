class CreateFunds < ActiveRecord::Migration
  def change
    create_table :funds do |t|
      t.string :name,               null:false, default:"unnamed fund"
      t.integer :balance,           null:false, default:0
      t.string :currency_label,     null:false, default:"EUR"
      t.integer :overdraft_limit,   null:false, default:0
      t.string :termination_policy, null:false, default:"suspend"

    end

    # Add backreference in Appliances
    # Also extend Appliances with a column which will specify last billing date
    # This is useful in case of AIR2 failures (we cannot guarantee that billing will be performed on a hourly basis)
    change_table :appliances do |t|
      t.belongs_to :fund
      t.column :last_billing, :datetime, null: true
    end
  end
end
