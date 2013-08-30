class CreateComputeSites < ActiveRecord::Migration
  def change
    create_table :compute_sites do |t|
      t.string :site_id, unique: true, null: false
      t.string :name
      t.string :location
      t.string :site_type, default: 'private'
      t.string :technology

      # openstack specific fields
      t.string :username
      t.string :api_key
      t.string :auth_method
      t.string :auth_url
      t.string :authtenant_name

      t.timestamps
    end
  end
end
