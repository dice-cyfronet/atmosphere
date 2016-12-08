class AddOptimizationPolicyToAppliances < ActiveRecord::Migration[4.2]
  def change
    add_column :atmosphere_appliances, :optimization_policy, :string
  end
end
