# == Schema Information
#
# Table name: compute_sites
#
#  id         :integer          not null, primary key
#  site_id    :string(255)
#  name       :string(255)
#  location   :string(255)
#  site_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe ComputeSite do

  subject { FactoryGirl.create(:compute_site) }
  expect_it { to be_valid }

  expect_it { to validate_presence_of :site_id }
  expect_it { to validate_presence_of :site_type }

  expect_it { to have_many :port_mapping_properties }
  expect_it { to ensure_inclusion_of(:site_type).in_array(%w(public private))}
end
