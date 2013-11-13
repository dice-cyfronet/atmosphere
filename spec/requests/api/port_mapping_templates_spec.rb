require 'spec_helper'

describe Api::V1::PortMappingTemplatesController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let(:security_proxy) { create(:security_proxy) }
  let!(:at1) { create(:filled_appliance_type, author: user, security_proxy: security_proxy) }
  let!(:at2) { create(:appliance_type, author: user) }
  let!(:pmt1) { create(:port_mapping_template, appliance_type: at1) }
  let!(:pmt2) { create(:port_mapping_template, appliance_type: at2) }

  describe 'GET /appliance_types/:appliance_type_id/port_mapping_templates' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as wrong user' do
      it 'returns 403 Forbidden error' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates", different_user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates", user)
        expect(response.status).to eq 200
      end

      it 'returns port mapping templates' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates", user)
        #p json_response
        expect(pmts_response).to be_an Array
        expect(pmts_response.size).to eq 1
        expect(pmts_response[0]).to port_mapping_template_eq pmt1
      end
    end
  end

  describe 'GET /appliance_types/:appliance_type_id/port_mapping_templates/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns chosen port mapping template' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user)
        #p json_response
        expect(pmt_response).to port_mapping_template_eq pmt1
      end

      it 'returns 404 Not Found when port mapping template is not found' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates/non_existing", user)
        expect(response.status).to eq 404
      end

      it 'returns 404 Not Found when appliance type is not found' do
        get api("/appliance_types/non_existing/port_mapping_templates/#{pmt1.id}", user)
        expect(response.status).to eq 404
      end

      it 'returns 404 Not Found when appliance type and port mapping template are not in relation' do
        get api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt2.id}", user)
        expect(response.status).to eq 404
      end
    end
  end


  describe 'POST /appliance_types/:appliance_type_id/port_mapping_templates' do
    let(:new_port_mapping_template_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'http',
          service_name: 'rdesktop',
          target_port: 3389
        }
      }
    end

    let(:wrong_port_mapping_template_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'wrong',
          service_name: 'rdesktop',
          target_port: 33
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliance_types/#{at1.id}/port_mapping_templates")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        post api("/appliance_types/#{at1.id}/port_mapping_templates", user), new_port_mapping_template_request
        expect(response.status).to eq 201
      end

      it 'creates new port mapping template' do
        expect {
          post api("/appliance_types/#{at1.id}/port_mapping_templates", user), new_port_mapping_template_request
        }.to change { PortMappingTemplate.count }.by(1)
      end

      it 'creates new port mapping template with correct attribute values' do
        post api("/appliance_types/#{at1.id}/port_mapping_templates", user), new_port_mapping_template_request
        expect(pmt_response['id']).to_not be_nil
        expect(pmt_response['transport_protocol']).to eq 'tcp'
        expect(pmt_response['application_protocol']).to eq 'http'
        expect(pmt_response['service_name']).to eq 'rdesktop'
        expect(pmt_response['target_port']).to eq 3389
        expect(pmt_response['appliance_type_id']).to eq at1.id
      end

      it 'returns 422 when transport and application protocols are wrong' do
        post api("/appliance_types/#{at1.id}/port_mapping_templates", user), wrong_port_mapping_template_request
        expect(response.status).to eq 422
      end

      it 'returns 403 Forbidden when creating port mapping template for not owned appliance type' do
        post api("/appliance_types/#{at1.id}/port_mapping_templates", different_user), new_port_mapping_template_request
        expect(response.status).to eq 403
      end

      it 'does not create new port mapping template for not owned appliance type' do
        expect {
          post api("/appliance_types/#{at1.id}/port_mapping_templates", different_user), new_port_mapping_template_request
        }.to change { PortMappingTemplate.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new port mapping template even for not owned appliance type' do
        expect {
          post api("/appliance_types/#{at1.id}/port_mapping_templates", admin), new_port_mapping_template_request
          expect(response.status).to eq 201
        }.to change { PortMappingTemplate.count }.by(1)
      end
    end

  end


  describe 'PUT /appliance_types/:appliance_type_id/port_mapping_templates/:id' do

    let(:update_json) do {port_mapping_template: {
        transport_protocol: 'udp',
        application_protocol: 'none',
        service_name: 'sth different'
    }} end

    let(:wrong_update_json) do {port_mapping_template: {
        transport_protocol: 'udp',
        application_protocol: 'https'
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates port mapping template' do
        old_target_port = pmt1.target_port
        old_appliance_type_id = pmt1.appliance_type.id
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user), update_json
        updated_pmt = PortMappingTemplate.find(pmt1.id)

        expect(updated_pmt).to be_updated_by_port_mapping_template update_json[:port_mapping_template]
        expect(pmt_response).to port_mapping_template_eq updated_pmt
        expect(updated_pmt.id).to_not be_nil
        expect(updated_pmt.id).to eq pmt1.id
        expect(updated_pmt['transport_protocol']).to eq 'udp'
        expect(updated_pmt['application_protocol']).to eq 'none'
        expect(updated_pmt['service_name']).to eq 'sth different'
        expect(updated_pmt['target_port']).to eq old_target_port
        expect(updated_pmt['appliance_type_id']).to eq old_appliance_type_id
        expect(updated_pmt['dev_mode_property_set_id']).to be_nil
      end

      it 'admin is able to update any port mapping template' do
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", admin), update_json
        expect(response.status).to eq 200
      end

      it 'returns 422 when transport and application protocols are wrong' do
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user), wrong_update_json
        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not the parent appliance type owner' do
        put api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", different_user), update_json
        expect(response.status).to eq 403
      end

      it 'return 404 Not Found when appliance type is not found or port mapping template is of different appliance type' do
        put api("/appliance_types/wrong_id/port_mapping_templates/#{pmt1.id}", user), update_json
        expect(response.status).to eq 404
        put api("/appliance_types/#{at2.id}/port_mapping_templates/#{pmt1.id}", user), update_json
        expect(response.status).to eq 404
      end
    end
  end


  describe 'DELETE /appliance_types/:appliance_type_id/port_mapping_templates/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        delete api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes own port mapping template' do
        expect {
          delete api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", user)
        }.to change { PortMappingTemplate.count }.by(-1)
      end

      it 'admin deletes any port mapping template' do
        expect {
          delete api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", admin)
        }.to change { PortMappingTemplate.count }.by(-1)
      end

      it 'returns 403 when user tries to delete not owned port mapping template' do
        expect {
          delete api("/appliance_types/#{at1.id}/port_mapping_templates/#{pmt1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { PortMappingTemplate.count }.by(0)
      end
    end
  end

  def pmts_response
    json_response['port_mapping_templates']
  end

  def pmt_response
    json_response['port_mapping_template']
  end

end
