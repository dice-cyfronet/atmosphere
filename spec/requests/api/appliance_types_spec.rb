require 'spec_helper'

describe API::ApplianceTypes do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:security_proxy) { create(:security_proxy) }
  let!(:at1) { create(:appliance_type, author: user, security_proxy: security_proxy) }

  describe 'GET /appliance_types' do
    let!(:at2) { create(:appliance_type) }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_types')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/appliance_types', user)
        expect(response.status).to eq 200
      end

      it 'returns appliance types' do
        get api('/appliance_types', user)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq 2

        expect(json_response[0]).to appliance_type_eq at1
        expect(json_response[1]).to appliance_type_eq at2
      end

      pending 'search'
      pending 'pagination'
    end
  end

  describe "GET /appliance_types/:id" do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_types/#{at1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance types' do
        get api("/appliance_types/#{at1.id}", user)
        expect(json_response).to appliance_type_eq at1
      end

      it 'returns 404 Not Found when appliance type is not found' do
        get api("/appliance_types/non_existing", user)
        expect(response.status).to eq 404
      end
    end
  end

  pending 'PUT /appliance_types/:id'
  pending 'DELETE /appliance_types/:id'
end