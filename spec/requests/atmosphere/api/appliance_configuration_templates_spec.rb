require 'rails_helper'

describe Atmosphere::Api::V1::ApplianceConfigurationTemplatesController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  let(:at1) { create(:appliance_type, author: user, visible_to: :owner) }
  let(:at2) { create(:appliance_type, visible_to: :all) }
  let(:at3) { create(:appliance_type, visible_to: :owner) }

  let!(:at1_config_tpl1) { create(:appliance_configuration_template, appliance_type: at1) }
  let!(:at1_config_tpl2) { create(:appliance_configuration_template, appliance_type: at1) }
  let!(:at2_config_tpl) { create(:appliance_configuration_template, appliance_type: at2) }
  let!(:at3_config_tpl) { create(:appliance_configuration_template, appliance_type: at3) }

  describe 'GET /appliance_configuration_templates' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_configuration_templates")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_configuration_templates", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance configuration templates' do
        get api("/appliance_configuration_templates", user)
        expect(acts_response).to be_an Array
        expect(acts_response.size).to eq 3

        expect(acts_response[0]).to config_template_eq at1_config_tpl1
        expect(acts_response[1]).to config_template_eq at1_config_tpl2
        expect(acts_response[2]).to config_template_eq at2_config_tpl
      end

      it 'returns appliance configuration templates for given appliance type' do
        get api("/appliance_configuration_templates?appliance_type_id=#{at1.id}", user)
        expect(acts_response.size).to eq 2

        expect(acts_response[0]).to config_template_eq at1_config_tpl1
        expect(acts_response[1]).to config_template_eq at1_config_tpl2
      end
    end

    context 'when authenticated as admin' do
      it 'returns all appliance configuration templates' do
        get api("/appliance_configuration_templates?all=true", admin)
        expect(acts_response.size).to eq 4
      end
    end

    context 'search' do
      it 'returns configuration assigned only to specific appliance_type' do
        get api("/appliance_configuration_templates?appliance_type_id=#{at1.id}", user)
        expect(acts_response.size).to eq 2

        expect(acts_response[0]).to config_template_eq at1_config_tpl1
        expect(acts_response[1]).to config_template_eq at1_config_tpl2
      end
    end
  end

  describe 'GET /appliance_configuration_templates/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_configuration_templates/#{at1_config_tpl1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance configuration template' do
        get api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user)
        expect(act_response).to config_template_eq at1_config_tpl1
      end

      it 'returns 403 Forbidden when accessing unpublished not owned appliance configuration template' do
        get api("/appliance_configuration_templates/#{at3_config_tpl.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'dynamic configuration' do
      let!(:dynamic_act) { create(:appliance_configuration_template, payload: '#{a} #{b} #{c}') }
      let!(:dynamic_act_with_mi_ticket) { create(:appliance_configuration_template, payload: '#{a} #{' + "#{Air.config.mi_authentication_key}}") }

      it 'returns information about parameters' do
        get api("/appliance_configuration_templates/#{dynamic_act.id}", admin)
        expect(act_response['parameters']).to eq ['a', 'b', 'c']
      end

      it 'remote mi_ticket from params list' do
        get api("/appliance_configuration_templates/#{dynamic_act_with_mi_ticket.id}", admin)
        expect(act_response['parameters']).to eq ['a']
      end
    end
  end

  context 'POST /appliance_configuration_templates' do
    let(:new_config_template_request) do
      {
        appliance_configuration_template: {
          name: 'config name',
          payload: 'payload',
          appliance_type_id: at1.id
        }
      }
    end

    let(:new_not_owned_config_template_request) do
      {
        appliance_configuration_template: {
          name: 'config name',
          payload: 'payload',
          appliance_type_id: at2.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliance_configuration_templates")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        post api("/appliance_configuration_templates", user), new_config_template_request
        expect(response.status).to eq 201
      end

      it 'creates new appliance configuration template' do
        expect {
          post api("/appliance_configuration_templates", user), new_config_template_request
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(1)
      end

      it 'creates new appliance configuration template with correct attrs values' do
        post api("/appliance_configuration_templates", user), new_config_template_request
        result = Atmosphere::ApplianceConfigurationTemplate.find(act_response['id'])
        expect(act_response).to config_template_eq result
      end

      it 'returns 403 Forbidden when creating configuration template for not owned appliance type' do
        post api("/appliance_configuration_templates", user), new_not_owned_config_template_request
      end

      it 'does not creates new configuration template when creating new one for not owned appliance type' do
        expect {
          post api("/appliance_configuration_templates", user), new_not_owned_config_template_request
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new configuration template even for not owned appliance type' do
        expect {
          post api("/appliance_configuration_templates", admin), new_not_owned_config_template_request
          expect(response.status).to eq 201
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(1)
      end
    end
  end

  context 'PUT /appliance_configuration_templates/{id}' do
    let(:update_request) do
      {
        appliance_configuration_template: {
          name: 'updated name',
          payload: 'updated payload'
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliance_configuration_templates/#{at1_config_tpl1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        put api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user), update_request
        expect(response.status).to eq 200
      end

      it 'updates appliance configuration template' do
        put api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user), update_request
        updated = Atmosphere::ApplianceConfigurationTemplate.find(at1_config_tpl1.id)
        expect(act_response).to config_template_eq updated
      end

      it 'returns 403 Forbidden when updating configuration template from not owned appliance type' do
        put api("/appliance_configuration_templates/#{at2_config_tpl.id}", user), update_request
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'updates configuration template even for not owned appliance type' do
        put api("/appliance_configuration_templates/#{at2_config_tpl.id}", admin), update_request
        expect(response.status).to eq 200
      end
    end
  end

  context 'DELETE /appliance_configuration_templates/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliance_configuration_templates/#{at1_config_tpl1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        delete api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes appliance configuration template' do
        expect {
          delete api("/appliance_configuration_templates/#{at1_config_tpl1.id}", user)
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(-1)
      end

      it 'returns 403 Forbidden when trying to remove configuration template from not owned appliance type' do
          delete api("/appliance_configuration_templates/#{at2_config_tpl.id}", user)
          expect(response.status).to eq 403
      end

      it 'does not remove configuration template from not owned appliance type' do
        expect {
          delete api("/appliance_configuration_templates/#{at2_config_tpl.id}", user)
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'deletes configuration template even from not owned appliance type' do
        expect {
          delete api("/appliance_configuration_templates/#{at2_config_tpl.id}", admin)
          expect(response.status).to eq 200
        }.to change { Atmosphere::ApplianceConfigurationTemplate.count }.by(-1)
      end
    end
  end

  def acts_response
    json_response['appliance_configuration_templates']
  end

  def act_response
    json_response['appliance_configuration_template']
  end
end