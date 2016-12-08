class AddOptimizationPolicyToApplianceSets < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_appliance_sets, :optimization_policy, :string
  end
end
