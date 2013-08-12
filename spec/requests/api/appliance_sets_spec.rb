require 'spec_helper'

describe API::ApplianceSets do
  include ApiHelpers

  let(:user) { create(:user) }

  describe 'GET /appliance_sets' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_sets')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/appliance_sets', user)
        expect(response.status).to eq 200
      end
    end
  end
end