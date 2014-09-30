require 'rails_helper'

describe Atmosphere::Api::V1::DevModePropertySetsController do
  include ApiHelpers

  let(:developer) { create(:developer) }
  let(:admin) { create(:admin) }

  let(:as) { create(:dev_appliance_set, user: developer) }
  let!(:appl1) { create(:appliance, appliance_set: as) }
  let!(:appl1_pmt) { create(:dev_port_mapping_template, dev_mode_property_set: appl1.dev_mode_property_set) }

  let!(:appl2) { create(:appliance, appliance_set: as) }

  let(:other_user_as) { create(:dev_appliance_set) }
  let!(:other_user_appl) { create(:appliance, appliance_set: other_user_as) }

  before do
    appl1.reload
  end

  describe 'GET /dev_mode_property_sets' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/dev_mode_property_sets")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        get api("/dev_mode_property_sets", developer)
        expect(response.status).to eq 200
      end

      it 'returns only owned dev mode properties sets' do
        get api("/dev_mode_property_sets", developer)
        expect(dev_props_response).to be_an Array
        expect(dev_props_response.size).to eq 2
        expect(dev_props_response[0]).to dev_props_eq appl1.dev_mode_property_set
        expect(dev_props_response[1]).to dev_props_eq appl2.dev_mode_property_set
      end
    end

    context 'when authenticated as admin' do
      it 'returns all dev mode properties sets if all flag is set to true' do
        get api("/dev_mode_property_sets?all=true", admin)
        expect(dev_props_response.size).to eq 3
      end
    end

    context 'search' do
      it 'returns dev mode prop set created for given appliance type' do
        get api("/dev_mode_property_sets?appliance_id=#{appl2.id}", developer)
        expect(dev_props_response.size).to eq 1
        expect(dev_props_response[0]).to dev_props_eq appl2.dev_mode_property_set
      end
    end
  end

  describe 'GET /dev_mode_property_sets/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        get api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}", developer)
        expect(response.status).to eq 200
      end

      it 'returns owned dev mode properties set' do
        get api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}", developer)
        expect(dev_prop_response).to dev_props_eq appl1.dev_mode_property_set
      end

      it 'returns 403 (Forbidden) when getting not owned dev mode properties set' do
        get api("/dev_mode_property_sets/#{other_user_appl.dev_mode_property_set.id}", developer)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns not owned dev mode properties set' do
        get api("/dev_mode_property_sets/#{other_user_appl.dev_mode_property_set.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  describe 'PUT /dev_mode_property_sets/:id' do
    let(:sec_proxy) { create(:security_proxy) }
    let(:update_params) do
      {
        dev_mode_property_set: {
          name: 'new_name',
          description: 'new description',
          shared: true,
          scalable: true,
          preference_cpu: 3,
          preference_memory: 1234,
          preference_disk: 4321,
          security_proxy: sec_proxy.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        put api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}", developer)
        expect(response.status).to eq 200
      end

      it 'updates dev mode property set' do
        put api("/dev_mode_property_sets/#{appl1.dev_mode_property_set.id}", developer), update_params
        appl1.reload
        expect(appl1.dev_mode_property_set).to dev_props_be_updated_by update_params
        expect(dev_prop_response).to dev_props_eq appl1.dev_mode_property_set
      end

      it 'return 403 (Forbiden) when trying to update not owned dev mode props' do
        put api("/dev_mode_property_sets/#{other_user_appl.dev_mode_property_set.id}", developer), update_params
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'updates not owned dev mode property set' do
        put api("/dev_mode_property_sets/#{other_user_appl.dev_mode_property_set.id}", admin), update_params
        expect(response.status).to eq 200
      end
    end
  end

  def dev_props_response
    json_response['dev_mode_property_sets']
  end

  def dev_prop_response
    json_response['dev_mode_property_set']
  end
end