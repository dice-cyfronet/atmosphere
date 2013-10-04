require 'spec_helper'

describe Api::V1::ApplianceConfigurationTemplatesController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  let(:at1) { create(:appliance_type, author: user, visibility: :unpublished) }
  let(:at2) { create(:appliance_type, visibility: :published) }
  let(:at3) { create(:appliance_type, visibility: :unpublished) }

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
        }.to change { ApplianceConfigurationTemplate.count }.by(1)
      end

      it 'creates new appliance configuration template with correct attrs values' do
        post api("/appliance_configuration_templates", user), new_config_template_request
        result = ApplianceConfigurationTemplate.find(act_response['id'])
        expect(act_response).to config_template_eq result
      end

      it 'returns 403 Forbidden when creating configuration template for not owned appliance type' do
        post api("/appliance_configuration_templates", user), new_not_owned_config_template_request
      end

      it 'does not creates new configuration template when creating new one for not owned appliance type' do
        expect {
          post api("/appliance_configuration_templates", user), new_not_owned_config_template_request
        }.to change { ApplianceConfigurationTemplate.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new configuration template even for not owned appliance type' do
        expect {
          post api("/appliance_configuration_templates", admin), new_not_owned_config_template_request
          expect(response.status).to eq 201
        }.to change { ApplianceConfigurationTemplate.count }.by(1)
      end
    end
  end

  pending 'PUT /appliance_configuration_templates/{id}'
  pending 'DELETE /appliance_configuration_templates/{id}'

  def acts_response
    json_response['appliance_configuration_templates']
  end

  def act_response
    json_response['appliance_configuration_template']
  end
end