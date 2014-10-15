class CreateComputeSites < ActiveRecord::Migration
  def change
    create_table :atmosphere_compute_sites do |t|
      t.string :site_id, unique: true, null: false
      t.string :name
      t.string :location
      t.string :site_type, default: 'private'
      t.string :technology
      t.boolean :regenerate_proxy_conf, default: false

      t.string :http_proxy_url
      t.string :https_proxy_url

      # a JSON string with cloud site specific configuration
      t.text :config

      # a JSON string with a hash of filters used when getting templates from compute site.
      t.text :template_filters

      t.timestamps
    end
  end
end
