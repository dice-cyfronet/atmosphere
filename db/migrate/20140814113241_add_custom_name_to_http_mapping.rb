class AddCustomNameToHttpMapping < ActiveRecord::Migration
  def change
   add_column :http_mappings, :custom_name, :string
   add_column :http_mappings, :base_url, :string, null: false
  end
end
