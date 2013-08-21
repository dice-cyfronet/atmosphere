class CreateComputeSites < ActiveRecord::Migration
  def change
    create_table :compute_sites do |t|
      t.string :site_id
      t.string :name
      t.string :location
      t.string :site_type

      t.timestamps
    end
  end
end
