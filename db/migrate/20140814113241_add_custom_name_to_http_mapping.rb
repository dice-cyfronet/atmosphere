class AddCustomNameToHttpMapping < ActiveRecord::Migration
  def change
   add_column :http_mappings, :custom_name, :string
  end
end
