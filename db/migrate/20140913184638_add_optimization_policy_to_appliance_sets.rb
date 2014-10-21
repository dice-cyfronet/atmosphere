class AddOptimizationPolicyToApplianceSets < ActiveRecord::Migration
  def change
    add_column :atmosphere_appliance_sets, :optimization_policy, :string
  end
end
