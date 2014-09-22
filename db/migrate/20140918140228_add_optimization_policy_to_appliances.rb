class AddOptimizationPolicyToAppliances < ActiveRecord::Migration
  def change
    add_column :appliances, :optimization_policy, :string
  end
end
