class AddOptimizationPolicyToAppliances < ActiveRecord::Migration
  def change
    add_column :atmosphere_appliances, :optimization_policy, :string
  end
end
