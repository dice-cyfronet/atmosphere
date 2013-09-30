require 'spec_helper'

describe Api::V1::ApplianceSetsController do
  include ApiHelpers

  let(:user)           { create(:developer) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let!(:portal_set)    { create(:appliance_set, user: user, appliance_set_type: :portal)}
  let!(:workflow1_set) { create(:appliance_set, user: user, appliance_set_type: :workflow)}
  let!(:differnt_user_workflow) { create(:appliance_set, user: different_user) }

  describe 'GET /appliance_sets' do
    let!(:workflow2_set)   { create(:appliance_set, user: user, appliance_set_type: :workflow)}
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
        expect(ases_response).to be_an Array
        expect(ases_response.size).to eq 4

        expect(ases_response[0]).to appliance_set_eq portal_set
        expect(ases_response[1]).to appliance_set_eq workflow1_set
        expect(ases_response[2]).to appliance_set_eq workflow2_set
        expect(ases_response[3]).to appliance_set_eq development_set
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
      let(:new_appliance_set) do
        { appliance_set: { name: 'my name', appliance_set_type: :workflow } }
      end

      it 'returns 201 Created on success' do
        post api('/appliance_sets', user), new_appliance_set
        expect(response.status).to eq 201
      end

      it 'creates second workflow appliance set' do
        expect {
          post api('/appliance_sets', user), new_appliance_set
          expect(as_response['id']).to_not be_nil
          expect(as_response['name']).to eq new_appliance_set[:appliance_set][:name]
          expect(as_response['appliance_set_type']).to eq new_appliance_set[:appliance_set][:appliance_set_type].to_s
        }.to change { ApplianceSet.count }.by(1)
      end

      it 'does not allow to create second portal appliance set' do
        expect {
          post api('/appliance_sets', user), {appliance_set: {name: 'second portal', appliance_set_type: :portal}}
          expect(response.status).to eq 409
        }.to change { ApplianceSet.count }.by(0)
      end

      it 'does not allow to create second development appliance set' do
        create(:appliance_set, user: user, appliance_set_type: :development)
        expect {
          post api('/appliance_sets', user), {appliance_set: {name: 'second portal', appliance_set_type: :development}}
          expect(response.status).to eq 409
        }.to change { ApplianceSet.count }.by(0)
      end

      it 'does not allow create development appliance set for non developer' do
        post api('/appliance_sets', non_developer), {appliance_set: {name: 'devel', appliance_set_type: :development}}
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
        expect(as_response).to appliance_set_eq portal_set
      end
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
      let(:update_request) do
        { appliance_set: { name: 'updated', priority: 99 } }
      end
      it 'returns 200 on success' do
        put api("/appliance_sets/#{portal_set.id}", user), update_request
        expect(response.status).to eq 200
      end

      it 'changes name and priority' do
        put api("/appliance_sets/#{portal_set.id}", user), update_request
        set = ApplianceSet.find(portal_set.id)
        expect(set.name).to eq 'updated'
        expect(set.priority).to eq 99
      end

      it 'does not change appliance set type' do
        put api("/appliance_sets/#{portal_set.id}", user), {appliance_set: {appliance_set_type: :workflow}}
        set = ApplianceSet.find(portal_set.id)
        expect(set.appliance_set_type).to eq 'portal'
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

      it 'returns 403 when deleting not owned appliance set' do
        expect {
          delete api("/appliance_sets/#{portal_set.id}", different_user)
          expect(response.status).to eq 403
        }.to change { ApplianceSet.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'deletes appliance set even when no set owner' do
        delete api("/appliance_sets/#{portal_set.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /appliance_sets/{id}/appliances' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliance_sets/#{portal_set.id}/appliances")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:static_config) { create(:static_config_template) }
      let(:static_request_body) do
        {
          appliance: {
            configuration_template_id: static_config.id
          }
        }
      end

      context 'with static config' do
        it 'returns 201 Created on success' do
          post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
          expect(response.status).to eq 201
        end

        it 'creates config instance' do
          expect {
            post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
          }.to change { ApplianceConfigurationInstance.count}.by(1)
        end

        it 'creates new appliance' do
          expect {
            post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
          }.to change { Appliance.count}.by(1)
        end

        it 'copies config payload from template' do
          post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
          config_instance = ApplianceConfigurationInstance.find(appliance_response['appliance_configuration_instance_id'])
          expect(config_instance.payload).to eq config_instance.appliance_configuration_template.payload
        end
      end

      context 'with appliance type already added to appliance set' do
        let(:config_instance) { create(:appliance_configuration_instance, payload: static_config.payload, appliance_configuration_template: static_config) }

        context 'when production appliance set' do
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: portal_set) }

          it 'returns 409 Conflict' do
            post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
            expect(response.status).to eq 409
          end

          it 'does not create new configuration instance' do
            expect {
              post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
            }.to change { ApplianceConfigurationInstance.count}.by(0)
          end

          it 'does not create new appliance' do
            expect {
              post api("/appliance_sets/#{portal_set.id}/appliances", user), static_request_body
            }.to change { Appliance.count}.by(0)
          end
        end

        context 'when development appliance set' do
          let(:development_set) { create(:appliance_set, user: user, appliance_set_type: :development)}
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: development_set) }

          it 'creates second appliance with the same configuration instance' do
            post api("/appliance_sets/#{development_set.id}/appliances", user), static_request_body
            expect(response.status).to eq 201
          end
        end
      end
    end
  end


  def ases_response
    json_response['appliance_sets']
  end

  def as_response
    json_response['appliance_set']
  end

  def appliance_response
    json_response['appliance']
  end
end