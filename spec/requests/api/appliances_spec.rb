require 'spec_helper'

describe Api::V1::AppliancesController do
  include ApiHelpers

  let(:optimizer) {double}

  let(:user)  { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:developer) { create(:developer) }


  let(:user_as) { create(:appliance_set, user: user) }
  let(:other_user_as) { create(:appliance_set, user: other_user) }

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

      context 'search' do
        let(:second_user_as) { create(:appliance_set, user: user) }
        let!(:second_as_appliance) { create(:appliance, appliance_set: second_user_as) }

        it 'returns only appliances belonging to select appliance set' do
          get api("/appliances?appliance_set_id=#{second_user_as.id}", user)
          expect(appliances_response.size).to eq 1
          expect(appliances_response[0]).to appliance_eq second_as_appliance
        end
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
    let!(:development_set) { create(:appliance_set, user: developer, appliance_set_type: :development)}

    let!(:public_at) { create(:appliance_type, visible_for: :all) }

    let(:static_config) { create(:static_config_template, appliance_type: public_at) }
    let(:static_request_body) { start_request(static_config, portal_set) }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("appliances"), static_request_body
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      before do
        Optimizer.stub(:instance).and_return(optimizer)
        expect(optimizer).to receive(:run).once
      end

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
        let(:dynamic_config) { create(:appliance_configuration_template, appliance_type: public_at, payload: 'dynamic config #{param1} #{param2} #{param3}') }
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
            expect(optimizer).to receive(:run).once
            post api("/appliances", user), static_request_body
            expect(response.status).to eq 201
          end
        end
      end
    end

    context 'with private appliance type (visible_for: owner)' do
      let(:private_at) { create(:appliance_type, author: user, visible_for: :owner) }
      let(:private_at_config) { create(:static_config_template, appliance_type: private_at) }

      it 'allows to start appliance type by its author' do
        post api("/appliances", user), start_request(private_at_config, portal_set)
        expect(response.status).to eq 201
      end

      it 'does not allow to start appliance by other user' do
        post api("/appliances", other_user), start_request(private_at_config, other_user_as)
        expect(response.status).to eq 403
      end
    end

    context 'with development appliance type (visible_for: developer)' do
      let(:development_at) { create(:appliance_type, visible_for: :developer) }
      let(:development_at_config) { create(:static_config_template, appliance_type: development_at) }

      it 'allows to start in development mode' do
        post api("/appliances", developer), start_request(development_at_config, development_set)
        expect(response.status).to eq 201
      end

      it 'does not allow to start in production mode' do
        post api("/appliances", user), start_request(development_at_config, portal_set)
        expect(response.status).to eq 403
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

  def start_request(at_config, appliance_set)
    {
      appliance: {
        configuration_template_id: at_config.id,
        appliance_set_id: appliance_set.id
      }
    }
  end
end