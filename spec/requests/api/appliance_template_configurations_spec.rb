require 'spec_helper'

describe Api::V1::ApplianceConfigurationTemplatesController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:at1) { create(:appliance_type) }
  let(:at2) { create(:appliance_type) }

  let!(:at1_config_tpl1) { create(:appliance_configuration_template, appliance_type: at1) }
  let!(:at1_config_tpl2) { create(:appliance_configuration_template, appliance_type: at1) }
  let!(:at2_config_tpl) { create(:appliance_configuration_template, appliance_type: at2) }

  describe 'GET /appliance_configuration_templates', focus: true do
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
        expect(act_response).to be_an Array
        expect(act_response.size).to eq 3

        expect(act_response[0]).to config_template_eq at1_config_tpl1
        expect(act_response[1]).to config_template_eq at1_config_tpl2
        expect(act_response[2]).to config_template_eq at1_config_tpl1
      end

      it 'returns appliance configuration templates for given appliance type' do
        get api("/appliance_configuration_templates?appliance_type_id=#{at1.id}", user)
        expect(act_response.size).to eq 2

        expect(act_response[0]).to config_template_eq at1_config_tpl1
        expect(act_response[1]).to config_template_eq at1_config_tpl2
      end
    end
  end

  def act_response
    json_response['appliance_configuration_templates']
  end
end