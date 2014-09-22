class AddOptimizationPolicyParamsToAppliances < ActiveRecord::Migration
  def change
    add_column :appliances, :optimization_policy_params, :text
  end
end
