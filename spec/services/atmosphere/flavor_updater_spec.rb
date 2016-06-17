require 'rails_helper'
require 'fog/openstack'

describe Atmosphere::FlavorUpdater do
  let(:os_tenant) { create(:openstack_tenant) }
  let(:t2) { create(:amazon_tenant) }

  describe 'T flavors' do
    context 'when creating a new tenant' do
      it 'registers tenants' do
        expect(os_tenant.virtual_machine_flavors.count).to eq 0
        expect(t2.virtual_machine_flavors.count).to eq 0
      end
    end

    context 'flavor does not exist in cloud any longer' do
      let!(:flavor) do
        create(:virtual_machine_flavor, tenant: os_tenant, active: true)
      end

      before :each do
        cloud_client = double('cloud client')
        allow(cloud_client).to receive(:flavors).and_return []
        allow(os_tenant).to receive(:cloud_client).and_return cloud_client
      end

      context 'no running vms using this flavor' do
        it 'removes flavor from db' do
          expect { Atmosphere::FlavorUpdater.new(os_tenant).execute }.
            to change(Atmosphere::VirtualMachineFlavor, :count).by(-1)
        end
      end

      context 'running vm uses this flavor' do
        it 'marks flavor as inactive' do
          create(:virtual_machine, virtual_machine_flavor: flavor)

          expect do
            Atmosphere::FlavorUpdater.new(os_tenant).execute
            flavor.reload
          end.to change(flavor, :active).from(true).to(false)
        end
      end
    end

    context 'when populating a tenant with flavors' do
      let!(:flavor6_ost) do
        create(:virtual_machine_flavor, tenant: os_tenant, id_at_site: '6',
                                        flavor_name: 'foo')
      end
      let!(:flavor6_aws) do
        create(:virtual_machine_flavor, tenant: t2, id_at_site: 'm1.medium',
                                        flavor_name: 'foo')
      end

      before do
        create(:virtual_machine_flavor, tenant: os_tenant, id_at_site: '5',
                                        flavor_name: 'bar')
      end

      it 'registers tenants with flavors' do
        expect(os_tenant.virtual_machine_flavors.count).to eq 2
        Atmosphere::FlavorUpdater.new(os_tenant).execute
        flavors_count = os_tenant.cloud_client.flavors.count
        expect(os_tenant.virtual_machine_flavors.count).to eq flavors_count
      end

      it 'updates existing flavour on openstack' do
        Atmosphere::FlavorUpdater.new(os_tenant).execute
        fog_flavor = os_tenant.cloud_client.flavors.detect do |f|
          f.id == flavor6_ost.id_at_site
        end

        flavor6_ost.reload
        expect(flavor6_ost).to flavor_eq fog_flavor
      end

      it 'updates existing flavour on aws' do
        Atmosphere::FlavorUpdater.new(t2).execute
        fog_flavor = t2.cloud_client.flavors.detect do |f|
          f.id == flavor6_aws.id_at_site
        end

        flavor6_aws.reload
        expect(flavor6_aws).to flavor_eq fog_flavor
      end

      it 'removes nonexistent flavor on openstack' do
        Atmosphere::FlavorUpdater.new(os_tenant).execute
        os_flavors_count = os_tenant.cloud_client.flavors.count
        expect(os_tenant.virtual_machine_flavors.count).to eq os_flavors_count
        # Add nonexistent flavor to tenant os_tenant
        create(:virtual_machine_flavor, tenant: os_tenant, id_at_site: 'foo',
                                        flavor_name: 'baz')
        os_tenant.reload
        baz_named_flavors_count = os_tenant.virtual_machine_flavors.
                                  where(flavor_name: 'baz').count
        expect(baz_named_flavors_count).to eq 1
        # Scan tenant again and expect flavor "baz" to be gone
        Atmosphere::FlavorUpdater.new(os_tenant).execute
        os_tenant.reload
        baz_named_flavors_count = os_tenant.virtual_machine_flavors.
                                  where(flavor_name: 'baz').count
        expect(baz_named_flavors_count).to eq 0
      end
    end

    context 'when idle' do
      it 'scans openstack tenant' do
        # Fog creates 7 mock flavors by default
        Atmosphere::FlavorUpdater.new(os_tenant).execute
        flavors_in_cloud = os_tenant.cloud_client.flavors.count
        expect(os_tenant.virtual_machine_flavors.count).to eq flavors_in_cloud

        # No further changes expected
        expect { Atmosphere::FlavorUpdater.new(os_tenant).execute }.
          not_to change(os_tenant.virtual_machine_flavors, :count)
      end

      it 'scans AWS tenant' do
        # Fog creates 7 mock flavors by default
        Atmosphere::FlavorUpdater.new(t2).execute
        flavors_in_aws = t2.cloud_client.flavors.count
        expect(t2.virtual_machine_flavors.count).to eq flavors_in_aws

        # No further changes expected
        expect { Atmosphere::FlavorUpdater.new(t2).execute }.
          not_to change(t2.virtual_machine_flavors, :count)
      end
    end
  end
end
