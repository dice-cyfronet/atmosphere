class CreateAtmosphereActionLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :atmosphere_action_logs do |t|
      t.string :message
      t.string :log_level
      t.references :action, index: true
      t.timestamps
    end
  end
end
