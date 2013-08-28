# == Schema Information
#
# Table name: virtual_machine_templates
#
#  id                 :integer          not null, primary key
#  id_at_site         :string(255)      not null
#  name               :string(255)      not null
#  state              :string(255)      not null
#  compute_site_id    :integer          not null
#  virtual_machine_id :integer
#  appliance_type_id  :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe VirtualMachineTemplate do
  pending "add some examples to (or delete) #{__FILE__}"
end
