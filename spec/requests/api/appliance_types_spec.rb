require 'spec_helper'

describe Api::V1::ApplianceTypesController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let(:security_proxy) { create(:security_proxy) }

  let!(:at1) { create(:filled_appliance_type, author: user, security_proxy: security_proxy) }
  let!(:at2) { create(:appliance_type) }

  describe 'GET /appliance_types' do
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
        expect(ats_response).to be_an Array
        expect(ats_response.size).to eq 2

        expect(ats_response[0]).to appliance_type_eq at1
        expect(ats_response[1]).to appliance_type_eq at2
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
        expect(at_response).to appliance_type_eq at1
      end

      it 'returns 404 Not Found when appliance type is not found' do
        get api("/appliance_types/non_existing", user)
        expect(response.status).to eq 404
      end
    end
  end

  describe 'PUT /appliance_types/:id' do
    let(:different_security_proxy) { create(:security_proxy, name: 'different/one') }

    let(:update_json) do {appliance_type: {
        name: 'new name',
        description: 'new description',
        shared: true,
        scalable: true,
        visibility: :published,
        preference_cpu: 10.0,
        preference_memory: 1024,
        preference_disk: 10240,
        security_proxy: different_security_proxy.id,
        author: different_user.id
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        put api("/appliance_types/#{at1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates appliance type' do
        put api("/appliance_types/#{at1.id}", user), update_json
        updated_at = ApplianceType.find(at1.id)

        expect(updated_at).to be_updated_by update_json[:appliance_type]
        expect(at_response).to appliance_type_eq updated_at
      end

      it 'admin updates appliance types event when no appliance type owner' do
        put api("/appliance_types/#{at1.id}", admin), update_json
        expect(response.status).to eq 200
      end

      it 'returns 400 when entity error' do
        put api("/appliance_types/#{at1.id}", user), { appliance_type: {preference_cpu: -2 }}
        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not an appliance type owner' do
        put api("/appliance_types/#{at1.id}", different_user), update_json
        expect(response.status).to eq 403
      end

      it 'return 404 Not Found when appliance type is not found' do
        put api("/appliance_types/non_existing", user), update_json
        expect(response.status).to eq 404
      end
    end
  end

  describe 'DELETE /appliance_types/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        delete api("/appliance_types/#{at1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes appliance type' do
        expect {
          delete api("/appliance_types/#{at1.id}", user)
        }.to change { ApplianceType.count }.by(-1)
      end

      it 'admin deletes appliance type even if no owner' do
        expect {
          delete api("/appliance_types/#{at1.id}", admin)
        }.to change { ApplianceType.count }.by(-1)
      end

      it 'returns 403 when user is not and appliance type owner' do
        expect {
          delete api("/appliance_types/#{at1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { ApplianceType.count }.by(0)
      end
    end
  end

  def ats_response
    json_response['appliance_types']
  end

  def at_response
    json_response['appliance_type']
  end
end