require 'rails_helper'

describe Api::V1::ApplianceConfigurationInstancesController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  let(:as) { create(:appliance_set, user: user) }

  let(:config_tpl) { create(:appliance_configuration_template) }

  let(:inst1) { create(:appliance_configuration_instance, appliance_configuration_template: config_tpl) }
  let(:inst2) { create(:appliance_configuration_instance, appliance_configuration_template: config_tpl) }
  let(:inst3) { create(:appliance_configuration_instance, appliance_configuration_template: config_tpl) }


  let!(:appl1) { create(:appliance, appliance_set: as, appliance_configuration_instance: inst1) }
  let!(:appl2) { create(:appliance, appliance_set: as, appliance_configuration_instance: inst2) }
  let!(:appl3) { create(:appliance, appliance_set: as,appliance_configuration_instance: inst2) }

  let!(:other_user_appl) { create(:appliance, appliance_configuration_instance: inst3) }

  describe 'GET /appliance_configuration_instances' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_configuration_instances")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_configuration_instances", user)
        expect(response.status).to eq 200
      end

      it 'returns only appliance configuration instances belonging to owned appliances' do
        get api("/appliance_configuration_instances", user)
        expect(insts_response).to be_an Array
        expect(insts_response.size).to eq 2
        expect(insts_response[0]).to config_instance_eq inst1
        expect(insts_response[1]).to config_instance_eq inst2
      end

      context 'search' do
        it 'returns configuration assigned into appliance' do
          get api("/appliance_configuration_instances?appliance_id=#{appl3.id}", user)
          expect(insts_response.size).to eq 1
          expect(insts_response[0]).to config_instance_eq inst2
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns all configuration instances when all flag set to true' do
        get api("/appliance_configuration_instances?all=true", admin)
        expect(insts_response.size).to eq 3
        expect(insts_response[0]).to config_instance_eq inst1
        expect(insts_response[1]).to config_instance_eq inst2
        expect(insts_response[2]).to config_instance_eq inst3
      end
    end
  end

  describe 'GET /appliance_configuration_instances/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_configuration_instances/#{inst1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_configuration_instances/#{inst1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns details about owned configuration instance' do
        get api("/appliance_configuration_instances/#{inst1.id}", user)
        expect(inst_response).to config_instance_eq inst1
      end

      it 'does not allow to see not owned configuration instance details' do
        get api("/appliance_configuration_instances/#{inst3.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns details about not owned configuration instance' do
        get api("/appliance_configuration_instances/#{inst3.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  def insts_response
    json_response['appliance_configuration_instances']
  end

  def inst_response
    json_response['appliance_configuration_instance']
  end
end