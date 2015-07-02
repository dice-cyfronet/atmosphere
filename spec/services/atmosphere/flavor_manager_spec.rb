require 'rails_helper'
require 'fog/openstack'

describe Atmosphere::FlavorManager do

  let(:t1) { create(:openstack_tenant) }
  let(:t2) { create(:amazon_tenant) }

  describe 'T flavors' do
    context 'when creating a new tenant' do
      it 'registers tenants' do
        expect(t1.virtual_machine_flavors.count).to eq 0
        expect(t2.virtual_machine_flavors.count).to eq 0
      end
    end

    context 'when populating a tenant with flavors' do
      let!(:flavor6_ost) { create(:virtual_machine_flavor, tenant: t1, id_at_site: '6', flavor_name: 'foo') }
      let!(:flavor6_aws) { create(:virtual_machine_flavor, tenant: t2, id_at_site: 'm1.medium', flavor_name: 'foo') }

      before do
        create(:virtual_machine_flavor, tenant: t1, id_at_site: '5', flavor_name: 'bar')
      end

      it 'registers tenants with flavors' do
        expect(t1.virtual_machine_flavors.count).to eq 2
        Atmosphere::FlavorManager::scan_tenant(t1)
        expect(t1.virtual_machine_flavors.count).to eq t1.cloud_client.flavors.count
      end

      it 'updates existing flavour on openstack' do
        Atmosphere::FlavorManager::scan_tenant(t1)
        fog_flavor = t1.cloud_client.flavors.detect { |f| f.id == flavor6_ost.id_at_site }

        flavor6_ost.reload
        expect(flavor6_ost).to flavor_eq fog_flavor
      end

      it 'updates existing flavour on aws' do
        Atmosphere::FlavorManager::scan_tenant(t2)
        fog_flavor = t2.cloud_client.flavors.detect { |f| f.id == flavor6_aws.id_at_site }

        flavor6_aws.reload
        expect(flavor6_aws).to flavor_eq fog_flavor
      end

      it 'removes nonexistent flavor on openstack' do
        Atmosphere::FlavorManager::scan_tenant(t1)
        expect(t1.virtual_machine_flavors.count).to eq t1.cloud_client.flavors.count
        # Add nonexistent flavor to tenant t1
        create(:virtual_machine_flavor, tenant: t1, id_at_site: 'foo', flavor_name: 'baz')
        t1.reload
        expect(t1.virtual_machine_flavors.where(flavor_name: 'baz').count).to eq 1
        # Scan tenant again and expect flavor "baz" to be gone
        Atmosphere::FlavorManager::scan_tenant(t1)
        t1.reload
        expect(t1.virtual_machine_flavors.where(flavor_name: 'baz').count).to eq 0
      end

    end

    context 'when idle' do
      it 'scans openstack tenant' do
        # Fog creates 7 mock flavors by default
        Atmosphere::FlavorManager::scan_tenant(t1)
        expect(t1.virtual_machine_flavors.count).to eq t1.cloud_client.flavors.count

        # No further changes expected
        Atmosphere::FlavorManager::scan_tenant(t1)
        expect(t1.virtual_machine_flavors.count).to eq t1.cloud_client.flavors.count
      end

      it 'scans AWS tenant' do
        # Fog creates 7 mock flavors by default
        Atmosphere::FlavorManager::scan_tenant(t2)
        expect(t2.virtual_machine_flavors.count).to eq t2.cloud_client.flavors.count

        # No further changes expected
        Atmosphere::FlavorManager::scan_tenant(t2)
        expect(t2.virtual_machine_flavors.count).to eq t2.cloud_client.flavors.count
      end
    end
  end
end