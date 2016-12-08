class RenameComputeSitesToTenants < ActiveRecord::Migration[4.2]
  def change
    rename_table :atmosphere_compute_sites, :atmosphere_tenants
    rename_column :atmosphere_tenants, :site_id, :tenant_id
    rename_column :atmosphere_tenants, :site_type, :tenant_type

    rename_table :atmosphere_compute_site_funds, :atmosphere_tenant_funds
    rename_column :atmosphere_tenant_funds, :compute_site_id, :tenant_id

    rename_column :atmosphere_virtual_machine_flavors, :compute_site_id, :tenant_id

    rename_column :atmosphere_virtual_machine_templates, :compute_site_id, :tenant_id

    rename_column :atmosphere_virtual_machines, :compute_site_id, :tenant_id

    rename_column :atmosphere_port_mapping_properties, :compute_site_id, :tenant_id

    rename_column :atmosphere_http_mappings, :compute_site_id, :tenant_id

    rename_table :atmosphere_appliance_compute_sites, :atmosphere_appliance_tenants
    rename_column :atmosphere_appliance_tenants, :compute_site_id, :tenant_id

    rename_column :atmosphere_migration_jobs, :compute_site_source_id, :tenant_source_id
    rename_column :atmosphere_migration_jobs, :compute_site_destination_id, :tenant_destination_id
  end
end
