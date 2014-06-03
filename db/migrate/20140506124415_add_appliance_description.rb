class AddApplianceDescription < ActiveRecord::Migration
  def change
    add_column :appliances, :description, :text, default: ''

    Appliance.all.find_each do |appl|
      at = appl.appliance_type
      if at
        appl.name = at.name if appl.name.blank?
        appl.description = at.description if appl.description.blank?
        appl.save!
      end
    end
  end
end
