# == Schema Information
#
# Table name: compute_sites
#
#  id                :integer          not null, primary key
#  site_id           :string(255)      not null
#  name              :string(255)
#  location          :string(255)
#  site_type         :string(255)      default("private")
#  technology        :string(255)
#  http_proxy_url    :string(255)
#  https_proxy_url   :string(255)
#  config            :text
#  template_filters  :text
#  created_at        :datetime
#  updated_at        :datetime
#  wrangler_url      :string(255)
#  wrangler_username :string(255)
#  wrangler_password :string(255)
#  active            :boolean          default(TRUE)
#

require 'rails_helper'

describe ComputeSite do

  before { Fog.mock! }

  subject { FactoryGirl.create(:compute_site, technology: 'openstack') }
  it { should be_valid }

  it { should validate_presence_of :site_id }
  it { should validate_presence_of :site_type }
  it { should validate_presence_of :technology }

  it { should have_many :port_mapping_properties }
  it { should have_many(:virtual_machine_templates).dependent(:destroy) }
  it { should have_many(:virtual_machines).dependent(:destroy) }

  it { should ensure_inclusion_of(:site_type).in_array(%w(public private))}

  context 'cloud' do
    context 'openstack' do
      it 'returns appropriate cloud client for openstack' do
        subject.config = '{"provider": "openstack", "openstack_auth_url":  "http://bzdura.com:5000/v2.0/tokens", "openstack_api_key":  "bzdura", "openstack_username": "bzdura"}'
        expect(subject.cloud_client).to be_an_instance_of(Fog::Compute::OpenStack::Mock)
      end
    end

    context 'aws' do
      let(:aws) { FactoryGirl.create(:compute_site, technology: 'aws', config: '{"provider": "aws", "aws_access_key_id": "bzdura",  "aws_secret_access_key": "bzdura",  "region": "eu-west-1"}') }
      it 'returns appropriate cloud client for aws' do
        expect(aws.cloud_client).to be_an_instance_of(Fog::Compute::AWS::Mock)
      end
    end
  end

  context 'if technology is present' do
    before { subject.technology = 'openstack' }
    it { should ensure_inclusion_of(:technology).in_array(%w(openstack aws))}
    it { should be_valid }
  end

  context 'if technology is invalid' do
    let(:invalid) { build(:compute_site, technology: 'INVALID_TECHNOLOGY') }
    it 'is invalid' do
      expect(invalid).to be_invalid
    end
  end

  context 'compute site is updated' do

    it 'recreates cloud client if configuration was updated' do
      expect(Fog::Compute).to receive(:new)
      subject.config = '{}'
      subject.save
    end

    it 'registers newly created cloud client in Air container if configuration was updated' do
      allow(Fog::Compute).to receive(:new)
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

    context 'config is blank' do

      it 'does not recreate cloud client' do
        expect(Fog::Compute).to_not receive(:new)
        subject.config = ''
        subject.save
      end

      it 'sets cloud client to nil if config is blank' do
        expect(Air).to receive(:unregister_cloud_client).with(subject.site_id)
        subject.config = ''
        subject.save
      end

    end

  end

  context 'compute site is destroyed' do
    it 'unregisters cloud client' do
      expect(Air).to receive(:unregister_cloud_client).with(subject.site_id)
      subject.destroy
    end
  end

  context '#with_appliance_type' do
    let(:compute_site) { create(:compute_site) }
    let(:vm) { create(:virtual_machine, compute_site: compute_site) }
    let(:at) { create(:appliance_type) }
    let!(:appl) { create(:appliance, appliance_type: at, virtual_machines: [ vm ]) }

    it 'loads not readonly compute sites' do
      ComputeSite.with_appliance_type(at).each do |cs|
        expect(cs.readonly?).to be_falsy
      end
    end
  end

  context '#with_dev_property_set' do
    let(:compute_site) { create(:compute_site) }
    let(:vm) { create(:virtual_machine, compute_site: compute_site) }
    let(:as) { create(:dev_appliance_set) }
    let!(:appl) { create(:appliance, appliance_set: as, virtual_machines: [ vm ]) }

    it 'loads not readonly compute sites' do
      ComputeSite.with_dev_property_set(appl.dev_mode_property_set).each do |cs|
        expect(cs.readonly?).to be_falsy
      end
    end
  end

  context '#proxy_urls_changed?' do
    let(:cs) { create(:compute_site) }

    it 'returns true when http proxy url changed' do
      cs.http_proxy_url = "updated"
      cs.save

      expect(cs.proxy_urls_changed?).to be_truthy
    end

    it 'returns true when https proxy url changed' do
      cs.https_proxy_url = "updated"
      cs.save

      expect(cs.proxy_urls_changed?).to be_truthy
    end

    it 'return false when other parameters updated' do
      cs.site_id = 'updated'
      cs.save

      expect(cs.proxy_urls_changed?).to be_falsy
    end
  end

  context '#site_id_previously_changed?' do
    let(:cs) { create(:compute_site) }

    it 'returns true when site_id changed' do
      cs.https_proxy_url = "updated"
      cs.save

      expect(cs.site_id_previously_changed?).to be_falsy
    end

    it 'returns false when other attribues changed' do
      cs.site_id = 'updated'
      cs.save

      expect(cs.site_id_previously_changed?).to be_truthy
    end
  end

  context '#default_flavor' do
    let(:first_flavor) { build(:virtual_machine_flavor) }
    let(:cs) do
      build(:compute_site).tap do |cs|
        cs.virtual_machine_flavors = [first_flavor, build(:virtual_machine_flavor)]
      end
    end

    it 'returns first flavor as default one' do
      expect(cs.default_flavor).to eq first_flavor
    end
  end

  context 'when active and non active compute sites' do
    it 'returns only active compute sites using default scope' do
      cs1 = create(:compute_site, active: true)
      create(:compute_site, active: false)
      cs3 = create(:compute_site, active: true)

      cses = ComputeSite.active

      expect(cses.count).to eq 2
      expect(cses).to include cs1
      expect(cses).to include cs3
    end
  end
end
