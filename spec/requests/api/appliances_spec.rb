require 'spec_helper'

describe Api::V1::AppliancesController do
  include ApiHelpers

  let(:user) { create(:user) }

  let(:user_as) { create(:appliance_set, user: user) }
  let(:other_user_as) { create(:appliance_set) }

  let!(:user_appliance1) { create(:appliance, appliance_set: user_as) }
  let!(:user_appliance2) { create(:appliance, appliance_set: user_as) }
  let!(:other_user_appliance) { create(:appliance, appliance_set: other_user_as) }

  describe 'GET /appliances' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliances")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliances", user)
        expect(response.status).to eq 200
      end

      it 'returns only user appliances' do
        get api("/appliances", user)
        expect(appliances_response).to be_an Array
        expect(appliances_response.size).to eq 2
        expect(appliances_response[0]).to appliance_eq user_appliance1
        expect(appliances_response[1]).to appliance_eq user_appliance2
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:admin) }

      it 'returns only owned appliances when no all flag' do
        get api("/appliances", admin)
        expect(appliances_response).to be_an Array
        expect(appliances_response.size).to eq 0
      end

      it 'returns all appliances when all flag set to true' do
        get api("/appliances?all=true", admin)
        expect(appliances_response.size).to eq 3
      end
    end
  end

  def appliances_response
    json_response['appliances']
  end
end