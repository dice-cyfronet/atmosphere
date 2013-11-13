require 'spec_helper'

describe Api::V1::EndpointsController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let(:security_proxy) { create(:security_proxy) }
  let!(:at1) { create(:filled_appliance_type, author: user, security_proxy: security_proxy, visible_for: 'owner') }
  let!(:at2) { create(:appliance_type, author: user, visible_for: 'all') }
  let!(:pmt1) { create(:port_mapping_template, appliance_type: at1) }
  let!(:pmt2) { create(:port_mapping_template, appliance_type: at2) }
  let!(:e1) { create(:endpoint, port_mapping_template: pmt1) }
  let!(:e2) { create(:endpoint, port_mapping_template: pmt2) }

  describe 'GET /endpoints' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as wrong user' do
      it 'returns 403 Forbidden error' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", different_user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns owned endpoints' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", user)
        #p json_response
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e1
      end

      it 'returns public endpoints' do
        get api("/endpoints?port_mapping_template_id=#{pmt2.id}", user)
        #p json_response
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e2
      end
    end
  end


  describe 'GET /endpoints/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/endpoints/#{e1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/endpoints/#{e1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns chosen owned endpoint' do
        get api("/endpoints/#{e1.id}", user)
        expect(e_response).to endpoint_eq e1
      end

      it 'returns chosen public endpoint' do
        get api("/endpoints/#{e2.id}", user)
        expect(e_response).to endpoint_eq e2
        get api("/endpoints/#{e2.id}", different_user)
        expect(e_response).to endpoint_eq e2
      end

      it 'refuses chosen not owned and not public endpoint' do
        get api("/endpoints/#{e1.id}", different_user)
        expect(response.status).to eq 403
      end

      it 'returns 404 Not Found when endpoint is not found' do
        get api("/endpoints/non_existing", user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'returns any chosen endpoint' do
        get api("/endpoints/#{e1.id}", admin)
        expect(e_response).to endpoint_eq e1
        get api("/endpoints/#{e2.id}", admin)
        expect(e_response).to endpoint_eq e2
      end
    end
  end


  describe 'POST /endpoints' do
    let(:new_request) do
      {
        endpoint: {
          description: 'some human description',
          descriptor: '<heavy xml="document">here</heavy>',
          endpoint_type: 'rest',
          port_mapping_template_id: pmt1.id
        }
      }
    end

    let(:wrong_request) do
      {
        endpoint: {
          description: 'some human description',
          descriptor: '<heavy xml="document">here</heavy>',
          endpoint_type: 'wrong type',
          port_mapping_template_id: pmt1.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/endpoints")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on success' do
        post api("/endpoints", user), new_request
        expect(response.status).to eq 201
      end

      it 'creates new endpoint' do
        expect {
          post api("/endpoints", user), new_request
        }.to change { Endpoint.count }.by(1)
      end

      it 'creates new endpoint with correct attribute values' do
        post api("/endpoints", user), new_request
        expect(e_response['id']).to_not be_nil
        expect(e_response['description']).to eq 'some human description'
        expect(e_response['descriptor']).to eq '<heavy xml="document">here</heavy>'
        expect(e_response['endpoint_type']).to eq 'rest'
        expect(e_response['port_mapping_template_id']).to eq pmt1.id
      end

      it 'returns 422 when endpoint type is wrong' do
        post api("/endpoints", user), wrong_request
        expect(response.status).to eq 422
      end

      it 'returns 403 Forbidden when creating endpoint for not owned port mapping template' do
        post api("/endpoints", different_user), new_request
        expect(response.status).to eq 403
      end

      it 'does not create new endpoint for not owned port mapping template' do
        expect {
          post api("/endpoints", different_user), new_request
        }.to change { Endpoint.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new endpoint even for not owned port mapping template' do
        expect {
          post api("/endpoints", admin), new_request
          expect(response.status).to eq 201
        }.to change { Endpoint.count }.by(1)
      end
    end

  end


  describe 'PUT /endpoints/:id' do

    let(:update_json) do {endpoint: {
        description: 'some human description',
        descriptor: 'nothing'
    }} end

    let(:wrong_update_json) do {endpoint: {
        endpoint_type: 'wrong type'
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/endpoints/#{e1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        put api("/endpoints/#{e1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates endpoint' do
        old_endpoint_type = e1.endpoint_type
        old_port_mapping_template_id = e1.port_mapping_template_id
        put api("/endpoints/#{e1.id}", user), update_json
        updated_e = Endpoint.find(e1.id)

        expect(updated_e).to be_updated_by_endpoint update_json[:endpoint]
        expect(e_response).to endpoint_eq updated_e
        expect(updated_e.id).to_not be_nil
        expect(updated_e.id).to eq e1.id
        expect(updated_e['description']).to eq 'some human description'
        expect(updated_e['descriptor']).to eq 'nothing'
        expect(updated_e['endpoint_type']).to eq old_endpoint_type
        expect(updated_e['port_mapping_template_id']).to eq old_port_mapping_template_id
      end

      it 'admin is able to update any endpoint' do
        put api("/endpoints/#{e1.id}", admin), update_json
        expect(response.status).to eq 200
      end

      it 'returns 422 when endpoint type is wrong' do
        put api("/endpoints/#{e1.id}", user), wrong_update_json
        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not the parent appliance type owner' do
        put api("/endpoints/#{e1.id}", different_user), update_json
        expect(response.status).to eq 403
      end
    end
  end


  describe 'DELETE /appliance_types/:appliance_type_id/port_mapping_templates/:port_mapping_template_id/endpoints/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/endpoints/#{e1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        delete api("/endpoints/#{e1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes own endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", user)
        }.to change { Endpoint.count }.by(-1)
      end

      it 'admin deletes any endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", admin)
        }.to change { Endpoint.count }.by(-1)
      end

      it 'returns 403 when user tries to delete not owned endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { Endpoint.count }.by(0)
      end
    end
  end

  def es_response
    json_response['endpoints']
  end

  def e_response
    json_response['endpoint']
  end

end
