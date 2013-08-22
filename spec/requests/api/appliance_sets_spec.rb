require 'spec_helper'

describe API::ApplianceSets do
  include ApiHelpers

  let(:user) { create(:developer) }
  let!(:portal_set) { create(:appliance_set, user: user, appliance_set_type: :portal)}
  let!(:workflow1_set) { create(:appliance_set, user: user, appliance_set_type: :workflow)}

  describe 'GET /appliance_sets' do
    let!(:workflow2_set) { create(:appliance_set, user: user, appliance_set_type: :workflow)}
    let!(:development_set) { create(:appliance_set, user: user, appliance_set_type: :development)}

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

      it 'returns user appliance sets' do
        get api('/appliance_sets', user)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq 4

        expect(json_response[0]).to appliance_set_eq portal_set
        expect(json_response[1]).to appliance_set_eq workflow1_set
        expect(json_response[2]).to appliance_set_eq workflow2_set
        expect(json_response[3]).to appliance_set_eq development_set
      end
    end
  end

  describe 'POST /appliances_sets' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api('/appliance_sets')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:non_developer) { create(:user) }
      let(:new_appliance_set) { {name: 'my name', type: :workflow} }

      it 'returns 201 Created on success' do
        post api('/appliance_sets', user), new_appliance_set
        expect(response.status).to eq 201
      end

      it 'creates second workflow appliance set' do
        expect {
          post api('/appliance_sets', user), new_appliance_set
          expect(json_response['id']).to_not be_nil
          expect(json_response['name']).to eq new_appliance_set[:name]
          expect(json_response['type']).to eq new_appliance_set[:type].to_s

        }.to change { ApplianceSet.count }.by(1)
      end

      it 'does not allow to create second portal appliance set' do
        expect {
          post api('/appliance_sets', user), {name: 'second portal', type: :portal}
          expect(response.status).to eq 400
        }.to change { ApplianceSet.count }.by(0)
      end

      it 'does not allow to create second development appliance set' do
        create(:appliance_set, user: user, appliance_set_type: :development)
        expect {
          post api('/appliance_sets', user), {name: 'second portal', type: :development}
          expect(response.status).to eq 400
        }.to change { ApplianceSet.count }.by(0)
      end

      it 'does not allow create development appliance set for non developer' do
        post api('/appliance_sets', non_developer), {name: 'devel', type: :development}
        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET /appliance_sets/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_sets/#{portal_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliance_sets/#{portal_set.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns portal appliance set' do
        get api("/appliance_sets/#{portal_set.id}", user)
        expect(json_response).to appliance_set_eq portal_set
      end
    end

    describe 'PUT /appliance_sets/{id}' do
      context 'when unauthenticated' do
        it 'returns 401 Unauthorized error' do
          put api("/appliance_sets/#{portal_set.id}")
          expect(response.status).to eq 401
        end
      end

      context 'when authenticated as user' do
        it 'returns 200 on success' do
          put api("/appliance_sets/#{portal_set.id}", user), {name: 'updated', priority: 99}
          expect(response.status).to eq 200
        end

        it 'changes name and priority' do
          put api("/appliance_sets/#{portal_set.id}", user), {name: 'updated', priority: 99}
          set = ApplianceSet.find(portal_set.id)
          expect(set.name).to eq 'updated'
          expect(set.priority).to eq 99
        end
      end
    end

    describe 'DELETE /appliance_sets/{id}' do
      context 'when unauthenticated' do
        it 'returns 401 Unauthorized error' do
          delete api("/appliance_sets/#{portal_set.id}")
          expect(response.status).to eq 401
        end
      end

      context 'when authenticated as user' do
        it 'returns 200 on success' do
          delete api("/appliance_sets/#{portal_set.id}", user)
          expect(response.status).to eq 200
        end

        it 'deletes appliance set' do
          expect {
            delete api("/appliance_sets/#{portal_set.id}", user)
          }.to change { ApplianceSet.count }.by(-1)
        end
      end
    end


    pending 'POST /appliance_sets/{id}/appliances'
  end
end