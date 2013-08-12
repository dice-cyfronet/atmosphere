# == Schema Information
#
# Table name: appliancesets
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  context_id    :string(255)      not null
#  priority      :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  created_at    :datetime
#  updated_at    :datetime
#

class ApplianceSet < ActiveRecord::Base
end
