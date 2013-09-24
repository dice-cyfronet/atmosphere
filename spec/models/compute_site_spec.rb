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

  subject { FactoryGirl.create(:compute_site) }
  expect_it { to be_valid }

  expect_it { to validate_presence_of :site_id }
  expect_it { to validate_presence_of :site_type }

  expect_it { to have_many :port_mapping_properties }
  expect_it { to have_many(:virtual_machine_templates).dependent(:destroy) }
  expect_it { to have_many(:virtual_machines).dependent(:destroy) }

  expect_it { to ensure_inclusion_of(:site_type).in_array(%w(public private))}

  context 'if technology is present' do
    before { subject.technology = 'openstack' }
    expect_it { to ensure_inclusion_of(:technology).in_array(%w(openstack aws))}
    expect_it { to be_valid }
  end

  context 'if technology is invalid' do
    let(:invalid) { build(:compute_site, technology: 'INVALID_TECHNOLOGY') }
    it 'is invalid' do
      expect(invalid).to be_invalid
    end
  end
end
