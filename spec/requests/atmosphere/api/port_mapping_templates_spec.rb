require 'rails_helper'

describe Atmosphere::Api::V1::PortMappingTemplatesController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }
  let(:developer) { create(:developer) }

  let!(:at1) { create(:filled_appliance_type, author: user) }
  let!(:at2) { create(:appliance_type, author: user, visible_to: 'all') }
  let!(:pmt1) { create(:port_mapping_template, appliance_type: at1) }
  let!(:pmt2) { create(:port_mapping_template, appliance_type: at2) }

  let(:as) { create(:dev_appliance_set, user: developer) }
  let!(:appl1) { create(:appliance, appliance_set: as) }
  let!(:pmt3) { create(:dev_port_mapping_template, dev_mode_property_set: appl1.dev_mode_property_set, appliance_type: nil) }

  let(:at3) { create(:appliance_type, author: user, visible_to: 'all') }
  let(:appl2) { create(:appliance, appliance_set: as, appliance_type: at3) }
  let!(:pmt4) { create(:port_mapping_template, appliance_type: at3) }


  describe 'GET /port_mapping_templates' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mapping_templates?appliance_type_id=#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden error' do
        get api("/port_mapping_templates?appliance_type_id=#{at1.id}", different_user)
        expect(response.status).to eq 403
        get api("/port_mapping_templates?dev_mode_property_set_id=#{appl1.dev_mode_property_set.id}", different_user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success for AT owner' do
        get api("/port_mapping_templates?appliance_type_id=#{at1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns 200 Success for dev mode prop set owner' do
        get api("/port_mapping_templates?dev_mode_property_set_id=#{appl1.dev_mode_property_set.id}", developer)
        expect(response.status).to eq 200
      end

      it 'returns port mapping templates for owned appliance type' do
        get api("/port_mapping_templates?appliance_type_id=#{at1.id}", user)
        expect(pmts_response).to be_an Array
        expect(pmts_response.size).to eq 1
        expect(pmts_response[0]).to port_mapping_template_eq pmt1
      end

      it 'returns port mapping templates for owned appliance' do
        get api("/port_mapping_templates?dev_mode_property_set_id=#{appl1.dev_mode_property_set.id}", developer)
        expect(pmts_response).to be_an Array
        expect(pmts_response.size).to eq 1
        expect(pmts_response[0]).to port_mapping_template_eq pmt3
      end

      it 'returns public port mapping templates' do
        get api("/port_mapping_templates?appliance_type_id=#{at2.id}", user)
        expect(pmts_response).to be_an Array
        expect(pmts_response.size).to eq 1
        expect(pmts_response[0]).to port_mapping_template_eq pmt2
        get api("/port_mapping_templates?appliance_type_id=#{at2.id}", different_user)
        expect(pmts_response).to be_an Array
        expect(pmts_response.size).to eq 1
        expect(pmts_response[0]).to port_mapping_template_eq pmt2
      end
    end
  end


  describe 'GET /port_mapping_templates/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden error for not public resources' do
        get api("/port_mapping_templates/#{pmt1.id}", different_user)
        expect(response.status).to eq 403
      end

      it 'returns 200 Success for public resources' do
        get api("/port_mapping_templates/#{pmt2.id}", different_user)
        expect(response.status).to eq 200
      end

      it 'returns chosen public port mapping template' do
        get api("/port_mapping_templates/#{pmt2.id}", different_user)
        expect(pmt_response).to port_mapping_template_eq pmt2
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        get api("/port_mapping_templates/#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns chosen owned port mapping template' do
        get api("/port_mapping_templates/#{pmt1.id}", user)
        expect(pmt_response).to port_mapping_template_eq pmt1
      end

      it 'returns 404 Not Found when port mapping template is not found' do
        get api("/port_mapping_templates/non_existing", user)
        expect(response.status).to eq 404
      end
    end
  end


  describe 'POST /port_mapping_templates' do
    let(:new_port_mapping_template_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'http',
          service_name: 'rdesktop',
          target_port: 3389,
          appliance_type_id: at1.id
        }
      }
    end

    let(:new_dev_port_mapping_template_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'http',
          service_name: 'rdesktop',
          target_port: 3389,
          dev_mode_property_set_id: appl1.dev_mode_property_set.id
        }
      }
    end

    let(:wrong_port_mapping_template_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'wrong',
          service_name: 'rdesktop',
          target_port: 33,
          appliance_type_id: at1.id
        }
      }
    end

    let(:pmt_for_used_at_request) do
      {
        port_mapping_template: {
          transport_protocol: 'tcp',
          application_protocol: 'http',
          service_name: 'rdesktop',
          target_port: 3389,
          appliance_type_id: at3.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/port_mapping_templates"), new_port_mapping_template_request
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden when creating port mapping template for not owned appliance type' do
        post api("/port_mapping_templates", different_user), new_port_mapping_template_request
        expect(response.status).to eq 403
        post api("/port_mapping_templates", different_user), new_dev_port_mapping_template_request
        expect(response.status).to eq 403
      end

      it 'does not create new port mapping template for not owned appliance type' do
        expect {
          post api("/port_mapping_templates", different_user), new_port_mapping_template_request
        }.to change { Atmosphere::PortMappingTemplate.count }.by(0)
      end
    end

    context 'when authenticated as owner' do
      it 'return 201 when PMT added to AT' do
        post api("/port_mapping_templates", user), new_port_mapping_template_request
        expect(response.status).to eq 201
      end

      it 'return 201 when PMT added to dev mode prop set' do
        post api("/port_mapping_templates", developer), new_dev_port_mapping_template_request
        expect(response.status).to eq 201
      end

      it 'creates new port mapping template' do
        expect {
          post api("/port_mapping_templates", user), new_port_mapping_template_request
        }.to change { Atmosphere::PortMappingTemplate.count }.by(1)
      end

      it 'creates new development mode port mapping template' do
        expect {
          post api("/port_mapping_templates", developer), new_dev_port_mapping_template_request
        }.to change { Atmosphere::PortMappingTemplate.count }.by(1)
      end

      it 'creates new port mapping template with correct attribute values' do
        post api("/port_mapping_templates", user), new_port_mapping_template_request
        expect(pmt_response['id']).to_not be_nil
        expect(pmt_response['transport_protocol']).to eq 'tcp'
        expect(pmt_response['application_protocol']).to eq 'http'
        expect(pmt_response['service_name']).to eq 'rdesktop'
        expect(pmt_response['target_port']).to eq 3389
        expect(pmt_response['appliance_type_id']).to eq at1.id
      end

      it 'creates new development mode port mapping template with correct attribute values' do
        post api("/port_mapping_templates", developer), new_dev_port_mapping_template_request
        expect(pmt_response['id']).to_not be_nil
        expect(pmt_response['transport_protocol']).to eq 'tcp'
        expect(pmt_response['application_protocol']).to eq 'http'
        expect(pmt_response['service_name']).to eq 'rdesktop'
        expect(pmt_response['target_port']).to eq 3389
        expect(pmt_response['dev_mode_property_set_id']).to eq appl1.dev_mode_property_set.id
      end

      it 'returns 422 when transport and application protocols are wrong' do
        post api("/port_mapping_templates", user), wrong_port_mapping_template_request
        expect(response.status).to eq 422
      end
    end

    context 'when authenticated as admin' do
      it 'creates new port mapping template even for not owned appliance type' do
        expect {
          post api("/port_mapping_templates", admin), new_port_mapping_template_request
          expect(response.status).to eq 201
        }.to change { Atmosphere::PortMappingTemplate.count }.by(1)
      end
    end

  end


  describe 'PUT /port_mapping_templates/:id' do

    let(:update_json) do {port_mapping_template: {
        transport_protocol: 'udp',
        application_protocol: 'none',
        service_name: 'sth-different'
    }} end

    let(:wrong_update_json) do {port_mapping_template: {
        transport_protocol: 'udp',
        application_protocol: 'https'
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 when user is not the parent appliance type owner' do
        put api("/port_mapping_templates/#{pmt1.id}", different_user), update_json
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        put api("/port_mapping_templates/#{pmt1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates port mapping template' do
        old_target_port = pmt1.target_port
        old_appliance_type_id = pmt1.appliance_type.id
        put api("/port_mapping_templates/#{pmt1.id}", user), update_json
        updated_pmt = Atmosphere::PortMappingTemplate.find(pmt1.id)

        expect(updated_pmt).to be_updated_by_port_mapping_template update_json[:port_mapping_template]
        expect(pmt_response).to port_mapping_template_eq updated_pmt
        expect(updated_pmt.id).to_not be_nil
        expect(updated_pmt.id).to eq pmt1.id
        expect(updated_pmt['transport_protocol']).to eq 'udp'
        expect(updated_pmt['application_protocol']).to eq 'none'
        expect(updated_pmt['service_name']).to eq 'sth-different'
        expect(updated_pmt['target_port']).to eq old_target_port
        expect(updated_pmt['appliance_type_id']).to eq old_appliance_type_id
        expect(updated_pmt['dev_mode_property_set_id']).to be_nil
      end

      it 'returns 422 when transport and application protocols are wrong' do
        put api("/port_mapping_templates/#{pmt1.id}", user), wrong_update_json
        expect(response.status).to eq 422
      end

      it 'return 404 Not Found when port mapping template is not found' do
        put api("port_mapping_templates/wrong_id", user), update_json
        expect(response.status).to eq 404
      end

      it 'does not allow to change assigment into AT' do
        put api("/port_mapping_templates/#{pmt1.id}", user),
            port_mapping_template: { appliance_type_id: at2.id }
        pmt1.reload

        expect(pmt1.appliance_type).to eq at1
      end

      it 'does not allow to change assigment into DMPS' do
        appl2 = create(:appliance, appliance_set: as)
        put api("/port_mapping_templates/#{pmt3.id}", user),
            port_mapping_template: {
              dev_mode_property_set_id: appl2.dev_mode_property_set.id
            }
        pmt3.reload

        expect(pmt3.dev_mode_property_set).to eq appl1.dev_mode_property_set
      end
    end

    context 'when authenticated as admin' do
      it 'is able to update any port mapping template' do
        put api("/port_mapping_templates/#{pmt1.id}", admin), update_json
        expect(response.status).to eq 200
      end
    end
  end


  describe 'DELETE /port_mapping_templates/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/port_mapping_templates/#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 when user tries to delete not owned port mapping template' do
        expect {
          delete api("/port_mapping_templates/#{pmt1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { Atmosphere::PortMappingTemplate.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'admin deletes any port mapping template' do
        expect {
          delete api("/port_mapping_templates/#{pmt1.id}", admin)
        }.to change { Atmosphere::PortMappingTemplate.count }.by(-1)
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        delete api("/port_mapping_templates/#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes own port mapping template' do
        expect {
          delete api("/port_mapping_templates/#{pmt1.id}", user)
        }.to change { Atmosphere::PortMappingTemplate.count }.by(-1)
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
