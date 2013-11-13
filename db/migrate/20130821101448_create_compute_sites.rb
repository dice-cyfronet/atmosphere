class CreateComputeSites < ActiveRecord::Migration
  def change
    create_table :compute_sites do |t|
      t.string :site_id, unique: true, null: false
      t.string :name
      t.string :location
      t.string :site_type, default: 'private'
      t.string :technology
      t.boolean :regenerate_proxy_conf, default: false

      # a JSON string with cloud site specific configuration
      t.text :config

      t.timestamps
    end
  end
end
