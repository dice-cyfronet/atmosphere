class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :name
      t.string :context_id,             :null => false
      t.integer :priority,              :null => false, :default => 50
      t.string :workflow_type,          :null => false, :default => 'development'

      t.timestamps
    end

    add_index :workflows, :context_id, unique: true
  end
end
