# == Schema Information
#
# Table name: tenants
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

describe Atmosphere::Tenant do

  before { Fog.mock! }

  subject { FactoryGirl.create(:tenant, technology: 'openstack') }
  it { should be_valid }

  it { should validate_presence_of :tenant_id }
  it { should validate_presence_of :tenant_type }
  it { should validate_presence_of :technology }

  it { should have_many :port_mapping_properties }
  it { should have_and_belong_to_many(:virtual_machine_templates) }
  it { should have_many(:virtual_machines).dependent(:destroy) }

  it { should validate_inclusion_of(:tenant_type).in_array(%w(public private))}

  context 'cloud' do
    context 'openstack' do
      it 'returns appropriate cloud client for openstack' do
        subject.config = '{"provider": "openstack", "openstack_auth_url":  "http://bzdura.com:5000/v2.0/tokens", "openstack_api_key":  "bzdura", "openstack_username": "bzdura"}'
        expect(subject.cloud_client).to be_an_instance_of(Fog::Compute::OpenStack::Mock)
      end
    end

    context 'aws' do
      let(:aws) { FactoryGirl.create(:tenant, technology: 'aws', config: '{"provider": "aws", "aws_access_key_id": "bzdura",  "aws_secret_access_key": "bzdura",  "region": "eu-west-1"}') }
      it 'returns appropriate cloud client for aws' do
        expect(aws.cloud_client).to be_an_instance_of(Fog::Compute::AWS::Mock)
      end
    end
  end

  context 'nic provider class' do
    context 'is misconfigured' do
      it 'is invalid if class does not exist' do
        misconfigured_t =
          build(:tenant, nic_provider_class_name: 'NotExistingClass')
        expect(misconfigured_t).to be_invalid
      end
      it 'is invalid if name does not point to a class' do
        misconfigured_t =
          build(:tenant, nic_provider_class_name: 'Atmosphere')
        expect(misconfigured_t).to be_invalid
      end
    end
    context 'is configured fine' do
      it 'is valid if class exist' do
        t = build(:tenant, nic_provider_class_name: 'String')
        expect(t).to be_valid
      end
      it 'is valid if class name is nil' do
        t = build(:tenant, nic_provider_class_name: nil)
        expect(t).to be_valid
      end
      it 'is valid if class name is empty string' do
        t = build(:tenant, nic_provider_class_name: '')
        expect(t).to be_valid
      end
    end
  end

  context 'if technology is present' do
    before { subject.technology = 'openstack' }
    it { should validate_inclusion_of(:technology).in_array(%w(openstack aws))}
    it { should be_valid }
  end

  context 'if technology is invalid' do
    let(:invalid) { build(:tenant, technology: 'INVALID_TECHNOLOGY') }
    it 'is invalid' do
      expect(invalid).to be_invalid
    end
  end

  context 'tenant is updated' do

    it 'recreates cloud client if configuration was updated' do
      expect(Fog::Compute).to receive(:new)
      subject.config = '{}'
      subject.save
    end

    it 'registers newly created cloud client in Air container if configuration was updated' do
      allow(Fog::Compute).to receive(:new)
      expect(Atmosphere).to receive(:register_cloud_client)
      subject.config = '{}'
      subject.save
    end

    it 'does not recreate cloud client if other attribute was updated' do
      expect(Fog::Compute).to_not receive(:new)
      subject.name = 'modified name'
      subject.save
    end

    it 'does not register cloud client in Air container if other attribute was updated' do
      expect(Atmosphere).to_not receive(:register_cloud_client)
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
        expect(Atmosphere).to receive(:unregister_cloud_client).with(subject.tenant_id)
        subject.config = ''
        subject.save
      end

    end

  end

  context 'tenant is destroyed' do
    it 'unregisters cloud client' do
      expect(Atmosphere).to receive(:unregister_cloud_client).with(subject.tenant_id)
      subject.destroy
    end
  end

  context '#with_appliance_type' do
    let(:tenant) { create(:tenant) }
    let(:vm) { create(:virtual_machine, tenant: tenant) }
    let(:at) { create(:appliance_type) }
    let!(:appl) { create(:appliance, appliance_type: at, virtual_machines: [ vm ]) }

    it 'loads not readonly tenants' do
      Atmosphere::Tenant.with_appliance_type(at).each do |t|
        expect(t.readonly?).to be_falsy
      end
    end
  end

  context '#with_dev_property_set' do
    let(:tenant) { create(:tenant) }
    let(:vm) { create(:virtual_machine, tenant: tenant) }
    let(:as) { create(:dev_appliance_set) }
    let!(:appl) { create(:appliance, appliance_set: as, virtual_machines: [ vm ]) }

    it 'loads not readonly tenants' do
      Atmosphere::Tenant.with_dev_property_set(appl.dev_mode_property_set).each do |t|
        expect(t.readonly?).to be_falsy
      end
    end
  end

  context '#proxy_urls_changed?' do
    let(:t) { create(:tenant) }

    it 'returns true when http proxy url changed' do
      t.http_proxy_url = "updated"
      t.save

      expect(t.proxy_urls_changed?).to be_truthy
    end

    it 'returns true when https proxy url changed' do
      t.https_proxy_url = "updated"
      t.save

      expect(t.proxy_urls_changed?).to be_truthy
    end

    it 'return false when other parameters updated' do
      t.tenant_id = 'updated'
      t.save

      expect(t.proxy_urls_changed?).to be_falsy
    end
  end

  context '#tenant_id_previously_changed?' do
    let(:t) { create(:tenant) }

    it 'returns true when tenant_id changed' do
      t.https_proxy_url = "updated"
      t.save

      expect(t.tenant_id_previously_changed?).to be_falsy
    end

    it 'returns false when other attribues changed' do
      t.tenant_id = 'updated'
      t.save

      expect(t.tenant_id_previously_changed?).to be_truthy
    end
  end

  context '#default_flavor' do
    let(:first_flavor) { build(:virtual_machine_flavor) }
    let(:t) do
      build(:tenant).tap do |t|
        t.virtual_machine_flavors = [first_flavor, build(:virtual_machine_flavor)]
      end
    end

    it 'returns first flavor as default one' do
      expect(t.default_flavor).to eq first_flavor
    end
  end

  context 'when active and non active tenants' do
    it 'returns only active tenants using default scope' do
      t1 = create(:tenant, active: true)
      create(:tenant, active: false)
      t3 = create(:tenant, active: true)

      ts = Atmosphere::Tenant.active

      expect(ts.count).to eq 2
      expect(ts).to include t1
      expect(ts).to include t3
    end
  end

  describe '#funded_by' do
    before :each do
      @t = create(:tenant)
    end

    it 'returns empty table when no funding found' do
      expect(Atmosphere::Tenant.funded_by(create(:fund))).to eq []
    end

    it 'selects only funded subset of tenants' do
      @t.funds << create(:fund)
      expect(Atmosphere::Tenant.funded_by(create(:fund))).to eq []
      create(:tenant, funds: [create(:fund)])
      t2 = create(:tenant, funds: [create(:fund), @t.funds.first])
      expect(Atmosphere::Fund.count).to eq 4
      expect(Atmosphere::Tenant.count).to eq 3
      expect(Atmosphere::Tenant.funded_by(@t.funds.first)).
        to match_array [@t, t2]
    end
  end
end
