require 'spec_helper'
require 'fog/openstack'

describe FlavorManager do

  let(:cs1) { create(:openstack_compute_site) }
  let(:cs2) { create(:amazon_compute_site) }

  describe 'CS flavors' do
    context 'when creating a new cloud site' do
      it 'registers cloud sites' do
        expect(cs1.virtual_machine_flavors.count).to eq 0
        expect(cs2.virtual_machine_flavors.count).to eq 0
      end
    end

    context 'when populating a cloud site with flavors' do
      let!(:flavor6_ost) { create(:virtual_machine_flavor, compute_site: cs1, id_at_site: "6", flavor_name: "foo") }
      let!(:flavor6_aws) { create(:virtual_machine_flavor, compute_site: cs2, id_at_site: "m1.medium", flavor_name: "foo") }

      before do
        create(:virtual_machine_flavor, compute_site: cs1, id_at_site: "5", flavor_name: "bar")
      end

      it 'registers compute sites with flavors' do
        expect(cs1.virtual_machine_flavors.count).to eq 2
        FlavorManager::scan_site(cs1)
        expect(cs1.virtual_machine_flavors.count).to eq cs1.cloud_client.flavors.count
      end

      it 'updates existing flavour on openstack' do
        FlavorManager::scan_site(cs1)
        fog_flavor = cs1.cloud_client.flavors.detect { |f| f.id == flavor6_ost.id_at_site }

        flavor6_ost.reload
        expect(flavor6_ost).to flavor_eq fog_flavor
      end

      it 'updates existing flavour on aws' do
        FlavorManager::scan_site(cs2)
        fog_flavor = cs2.cloud_client.flavors.detect { |f| f.id == flavor6_aws.id_at_site }

        flavor6_aws.reload
        expect(flavor6_aws).to flavor_eq fog_flavor
      end
    end

    context 'when idle' do
      it 'scans openstack cloud site' do
        # Fog creates 7 mock flavors by default
        FlavorManager::scan_site(cs1)
        expect(cs1.virtual_machine_flavors.count).to eq cs1.cloud_client.flavors.count

        # No further changes expected
        FlavorManager::scan_site(cs1)
        expect(cs1.virtual_machine_flavors.count).to eq cs1.cloud_client.flavors.count
      end

      it 'scans AWS cloud site' do
        # Fog creates 7 mock flavors by default
        FlavorManager::scan_site(cs2)
        expect(cs2.virtual_machine_flavors.count).to eq cs2.cloud_client.flavors.count

        # No further changes expected
        FlavorManager::scan_site(cs2)
        expect(cs2.virtual_machine_flavors.count).to eq cs2.cloud_client.flavors.count
      end
    end
  end
end