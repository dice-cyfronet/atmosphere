class AddMetadataGlobalIdToApplianceType < ActiveRecord::Migration
  def change
    change_table :appliance_types do |t|
      t.column :metadata_global_id, :string, null: true
    end
  end
end
