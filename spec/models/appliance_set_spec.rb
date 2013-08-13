# == Schema Information
#
# Table name: appliance_sets
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  context_id    :string(255)      not null
#  priority      :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe ApplianceSet do
  pending 'should not allow for null name,context_id,priority,appliance_set_type'
  pending 'should guarantee context_id uniqueness'
  pending 'should assign proper defaults: 50 and development'
  pending 'should not allow for other types than development, portal, workflow'
  pending 'should not allow for change of context_id and type'
end
