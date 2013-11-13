# == Schema Information
#
# Table name: compute_sites
#
#  id              :integer          not null, primary key
#  site_id         :string(255)      not null
#  name            :string(255)
#  location        :string(255)
#  site_type       :string(255)      default("private")
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

  before { Fog.mock! }

  subject { FactoryGirl.create(:compute_site, technology: 'openstack') }
  expect_it { to be_valid }

  expect_it { to validate_presence_of :site_id }
  expect_it { to validate_presence_of :site_type }
  expect_it { to validate_presence_of :technology }

  expect_it { to have_many :port_mapping_properties }
  expect_it { to have_many(:virtual_machine_templates).dependent(:destroy) }
  expect_it { to have_many(:virtual_machines).dependent(:destroy) }

  expect_it { to ensure_inclusion_of(:site_type).in_array(%w(public private))}

  context 'cloud' do
    context 'openstack' do
      it 'returns appropriate cloud client for openstack' do
        subject.config = '{"provider": "openstack", "openstack_auth_url":  "http://bzdura.com:5000/v2.0/tokens", "openstack_api_key":  "bzdura", "openstack_username": "bzdura"}'
        expect(subject.cloud_client).to be_an_instance_of(Fog::Compute::OpenStack::Mock)
      end
    end

    context 'aws' do
      subject { FactoryGirl.create(:compute_site, technology: 'aws', config: '{"provider": "aws", "aws_access_key_id": "bzdura",  "aws_secret_access_key": "bzdura",  "region": "eu-west-1"}') }
      it 'returns appropriate cloud client for aws' do
        expect(subject.cloud_client).to be_an_instance_of(Fog::Compute::AWS::Mock)
      end
    end
  end

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

  context 'compute site is updated' do

    it 'recreates cloud client if configuration was updated' do
      Fog::Compute.stub(:new)
      expect(Fog::Compute).to receive(:new)
      subject.config = '{}'
      subject.save
    end

    it 'registers newly created cloud client in Air container if configuration was updated' do
      Fog::Compute.stub(:new)
      expect(Air).to receive(:register_cloud_client)
      subject.config = '{}'
      subject.save
    end

    it 'does not recreate cloud client if other attribute was updated' do
      expect(Fog::Compute).to_not receive(:new)
      subject.name = 'modified name'
      subject.save
    end

    it 'does not register cloud client in Air container if other attribute was updated' do
      expect(Air).to_not receive(:register_cloud_client)
      subject.name = 'modified name'
      subject.save
    end

  end

end
