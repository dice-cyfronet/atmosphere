class AddOptimizationPolicyParamsToAppliances < ActiveRecord::Migration
  def change
    add_column :atmosphere_appliances, :optimization_policy_params, :text
  end
end
