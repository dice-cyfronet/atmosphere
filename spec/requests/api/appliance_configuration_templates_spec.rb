require 'spec_helper'

describe Api::V1::ApplianceConfigurationTemplatesController do
  include ApiHelpers

  let(:user) { create(:user) }
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

  pending 'POST /appliance_configuration_templates'
  pending 'PUT /appliance_configuration_templates/{id}'
  pending 'DELETE /appliance_configuration_templates/{id}'

  def acts_response
    json_response['appliance_configuration_templates']
  end

  def act_response
    json_response['appliance_configuration_template']
  end
end