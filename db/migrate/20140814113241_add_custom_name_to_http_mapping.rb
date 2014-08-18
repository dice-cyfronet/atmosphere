class AddCustomNameToHttpMapping < ActiveRecord::Migration
  def change
    add_column :http_mappings, :custom_name, :string
    add_column :http_mappings, :base_url, :string

    HttpMapping.all.each do |hm|
      hm.base_url = hm.application_protocol.http? ?
        hm.compute_site.http_proxy_url :
        hm.compute_site.https_proxy_url

      hm.save
    end

    change_column :http_mappings, :base_url, :string, null: false
  end
end
