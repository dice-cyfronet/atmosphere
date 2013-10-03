require 'spec_helper'

describe Api::V1::AppliancesController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

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

  describe 'GET /appliances/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliances/#{user_appliance1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliances/#{user_appliance1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance details' do
        get api("/appliances/#{user_appliance1.id}", user)
        expect(appliance_response).to appliance_eq user_appliance1
      end

      it 'returns 403 Forbidden when getting other user appliance details' do
        get api("/appliances/#{other_user_appliance.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns appliance details of other user appliance' do
        get api("/appliances/#{other_user_appliance.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /appliances' do
    let!(:portal_set) { create(:appliance_set, user: user, appliance_set_type: :portal)}
    let!(:development_set) { create(:appliance_set, user: user, appliance_set_type: :development)}

    let(:static_config) { create(:static_config_template) }
    let(:static_request_body) do
      {
        appliance: {
          configuration_template_id: static_config.id,
          appliance_set_id: portal_set.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("appliances"), static_request_body
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        post api("/appliances", user), static_request_body
        expect(response.status).to eq 201
      end

      context 'with static config' do
        it 'creates config instance' do
          expect {
            post api("/appliances", user), static_request_body
          }.to change { ApplianceConfigurationInstance.count}.by(1)
        end

        it 'creates new appliance' do
          expect {
            post api("/appliances", user), static_request_body
          }.to change { Appliance.count}.by(1)
        end

        it 'copies config payload from template' do
          post api("/appliances", user), static_request_body
          config_instance = ApplianceConfigurationInstance.find(appliance_response['appliance_configuration_instance_id'])
          expect(config_instance.payload).to eq config_instance.appliance_configuration_template.payload
        end
      end

      context 'with dynamic configuration' do
        let(:dynamic_config) { create(:appliance_configuration_template, payload: 'dynamic config #{param1} #{param2} #{param3}') }
        let(:dynamic_request_body) do
          {
            appliance: {
              configuration_template_id: dynamic_config.id,
              appliance_set_id: portal_set.id,
              params: {
                param1: 'a',
                param2: 'b',
                param3: 'c'
              }
            }
          }
        end

        it 'creates config instance with all required parameters' do
          post api("/appliances", user), dynamic_request_body
          expect(response.status).to eq 201
        end

        it 'creates dynamic configuration instance payload' do
          post api("/appliances", user), dynamic_request_body
          config_instance = ApplianceConfigurationInstance.find(appliance_response['appliance_configuration_instance_id'])
          expect(config_instance.payload).to eq 'dynamic config a b c'
        end
      end

      context 'with appliance type already added to appliance set' do
        let(:config_instance) { create(:appliance_configuration_instance, payload: static_config.payload, appliance_configuration_template: static_config) }
        let(:second_static_config) { create(:static_config_template) }

        context 'when production appliance set' do
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: portal_set, appliance_type: static_config.appliance_type) }

          it 'returns 409 Conflict' do
            post api("/appliances", user), static_request_body
            expect(response.status).to eq 409
          end

          it 'does not create new configuration instance' do
            expect {
              post api("/appliances", user), static_request_body
            }.to change { ApplianceConfigurationInstance.count}.by(0)
          end

          it 'does not create new appliance' do
            expect {
              post api("/appliances", user), static_request_body
            }.to change { Appliance.count}.by(0)
          end

          it 'creates new appliance when configuration payload the same but different appliance types' do
            post api("/appliances", user), {appliance: { configuration_template_id: second_static_config.id } }

          end
        end

        context 'when development appliance set' do
          let(:development_set) { create(:appliance_set, user: user, appliance_set_type: :development)}
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: development_set) }
          let(:static_request_body) do
            {
              appliance: {
                configuration_template_id: static_config.id,
                appliance_set_id: development_set.id
              }
            }
          end

          it 'creates second appliance with the same configuration instance' do
            post api("/appliances", user), static_request_body
            expect(response.status).to eq 201
          end
        end
      end
    end
  end

  context 'DELETE /appliances/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliances/#{user_appliance1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        delete api("/appliances/#{user_appliance1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes user appliance' do
        expect {
          delete api("/appliances/#{user_appliance1.id}", user)
        }.to change { Appliance.count }.by(-1)
      end

      it 'returns 403 Forbidden when trying to remove other user appliance' do
        delete api("/appliances/#{other_user_appliance.id}", user)
        expect(response.status).to eq 403
      end

      it 'does not remove other user appliance' do
        expect {
          delete api("/appliances/#{other_user_appliance.id}", user)
        }.to change { Appliance.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'removes other user appliance' do
        expect {
          delete api("/appliances/#{other_user_appliance.id}", admin)
          expect(response.status).to eq 200
        }.to change { Appliance.count }.by(-1)
      end
    end
  end

  def appliance_response
    json_response['appliance']
  end

  def appliances_response
    json_response['appliances']
  end
end