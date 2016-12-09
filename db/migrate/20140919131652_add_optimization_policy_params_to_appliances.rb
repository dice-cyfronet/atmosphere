class AddOptimizationPolicyParamsToAppliances < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_appliances, :optimization_policy_params, :text
  end
end
