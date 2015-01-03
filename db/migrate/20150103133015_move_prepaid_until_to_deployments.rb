# The purpose of this migration is to move the 'prepaid_until' column from Atmosphere::Appliance to Atmosphere::Deployment
# The reason for this is that an Appliance may have multiple deployments and new deployments may be added on the fly
# while the Appliance is running - in such cases, it is no longer sufficient to store a global 'prepaid_until' timestamp
# for the whole Appliance - rather, the billing system must iterate over the Appliance's deployments and bill each one
# separately.
class MovePrepaidUntilToDeployments < ActiveRecord::Migration
  def up
    add_column :atmosphere_deployments, :billing_state, :string, null:false, default:"prepaid"

    # Time for some good old-fashioned SQL because the Rails ORM model is too constraining to support current timestamp as default datetime
    execute "ALTER TABLE atmosphere_deployments ADD COLUMN prepaid_until TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP"

    # Now we need to iterate over existing Appliances and rewrite the relevant data in order to maintain appliance info
    Atmosphere::Appliance.find_each do |a|
      a.deployments.each do |dep|
        dep.billing_state = a.billing_state
        dep.prepaid_until = a.prepaid_until
        dep.save
      end
    end

    # Finally, we need to clean up Atmosphere::Appliance
    remove_column :atmosphere_appliances, :billing_state
    remove_column :atmosphere_appliances, :prepaid_until

  end

  def down
    # Sorry, this cannot be undone as there is no meaningful way to restore the values for Atmosphere::Appliance columns
    # in a situation where deployments are added and deleted while the Appliance is alive.
    raise ActiveRecord::IrreversibleMigration
  end
end
