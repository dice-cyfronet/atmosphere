class AddOptimizationPolicyToApplianceSets < ActiveRecord::Migration
  def change
    add_column :appliance_sets, :optimization_policy, :string
  end
end
