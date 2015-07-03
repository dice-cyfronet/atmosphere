class ExtendVmtToTenantRelationship < ActiveRecord::Migration
  def up
    # Spawn linking table
    create_table :atmosphere_virtual_machine_template_tenants do |t|
      t.references :virtual_machine_template
      t.references :tenant
    end
    # Rewrite existing data
    existing_templates = execute("SELECT id, tenant_id FROM atmosphere_virtual_machine_templates")
    existing_templates.each do |t|
      puts "Processing VMT #{t['id'].to_s} which belongs to tenant #{t['tenant_id'].to_s}"
      execute("INSERT INTO atmosphere_virtual_machine_template_tenants(virtual_machine_template_id, \
        tenant_id) VALUES(#{t['id'].to_s}, #{t['tenant_id'].to_s})")
    end
    # Get rid of old FKey
    # execute("ALTER TABLE atmosphere_virtual_machine_templates DROP COLUMN tenant_id")

  end

  def down
    # Despawn linking table
    drop_table :atmosphere_virtual_machine_template_tenants
  end
end
