# == Schema Information
#
# Table name: compute_sites
#
#  id              :integer          not null, primary key
#  site_id         :string(255)
#  name            :string(255)
#  location        :string(255)
#  site_type       :string(255)
#  technology      :string(255)
#  username        :string(255)
#  api_key         :string(255)
#  auth_method     :string(255)
#  auth_url        :string(255)
#  authtenant_name :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

require 'spec_helper'

describe ComputeSite do
  pending "add some examples to (or delete) #{__FILE__}"

  expect_it { to have_many :port_mapping_properties }

end
