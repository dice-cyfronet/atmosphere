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
      puts "Processing VMT #{t['id']} which belongs to tenant #{t['tenant_id']}"
      execute(
      <<-SQL
        INSERT INTO atmosphere_virtual_machine_template_tenants(virtual_machine_template_id, tenant_id)
        VALUES(#{t['id'].to_s}, #{t['tenant_id'].to_s})
        SQL
      )
    end
    # Get rid of old FKey
    execute("ALTER TABLE atmosphere_virtual_machine_templates DROP COLUMN tenant_id")

  end

  def down
    # Recreate tenant_id in vmts
    add_column :atmosphere_virtual_machine_templates, :tenant_id, :integer
    # Populate field
    ts = execute("SELECT virtual_machine_template_id AS vmid, MIN(tenant_id) AS tid FROM \
      atmosphere_virtual_machine_template_tenants GROUP BY(virtual_machine_template_id)")
    ts.each do |t|
      execute("UPDATE atmosphere_virtual_machine_templates SET tenant_id = #{t['tid']} WHERE id = #{t['vmid']}")
    end
    # Despawn linking table
    drop_table :atmosphere_virtual_machine_template_tenants

  end
end
