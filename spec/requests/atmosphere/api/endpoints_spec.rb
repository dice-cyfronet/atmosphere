require 'rails_helper'

describe Atmosphere::Api::V1::EndpointsController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }
  let(:developer) { create(:developer) }

  let!(:at1) { create(:filled_appliance_type, author: user, visible_to: 'owner') }
  let!(:at2) { create(:appliance_type, author: user, visible_to: 'all') }
  let!(:pmt1) { create(:port_mapping_template, appliance_type: at1) }
  let!(:pmt2) { create(:port_mapping_template, appliance_type: at2) }
  let!(:e1) { create(:endpoint, port_mapping_template: pmt1, secured: true) }
  let!(:e2) { create(:endpoint, port_mapping_template: pmt2) }

  let(:as) { create(:dev_appliance_set, user: developer) }
  let!(:appl1) { create(:appliance, appliance_set: as) }
  let!(:pmt3) { create(:dev_port_mapping_template, dev_mode_property_set: appl1.dev_mode_property_set, appliance_type: nil) }
  let!(:e3) { create(:endpoint, port_mapping_template: pmt3) }


  describe 'GET /endpoints' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns empty list when searching for non owned endpoint' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", different_user)
        expect(es_response).to eq []
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns owned endpoints' do
        get api("/endpoints?port_mapping_template_id=#{pmt1.id}", user)
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e1
      end

      it 'returns public endpoints' do
        get api("/endpoints?port_mapping_template_id=#{pmt2.id}", user)
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e2
        get api("/endpoints?port_mapping_template_id=#{pmt2.id}", different_user)
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e2
      end

      # TODO - FIXME - when properly dealt with abilities
      it 'returns all public endpoints' do
       get api("/endpoints", user)
       expect(es_response).to be_an Array
       expect(es_response.size).to eq 2
      end
    end

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        get api("/endpoints?port_mapping_template_id=#{pmt3.id}", developer)
        expect(response.status).to eq 200
      end

      it 'returns owned endpoints in development' do
        get api("/endpoints?port_mapping_template_id=#{pmt3.id}", developer)
        expect(es_response).to be_an Array
        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq e3
      end

      it 'returns development endpoints' do
        at = create(:appliance_type, visible_to: :developer)
        pmt = create(:port_mapping_template, appliance_type: at)
        endpoint = create(:endpoint, port_mapping_template: pmt)

        get api("/endpoints?port_mapping_template_id=#{pmt.id}", developer)

        expect(es_response.size).to eq 1
        expect(es_response[0]).to endpoint_eq endpoint
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

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden error for not public resources' do
        get api("/endpoints/#{e1.id}", different_user)
        expect(response.status).to eq 403
      end

      it 'returns 200 Success for public resources' do
        get api("/endpoints/#{e2.id}", different_user)
        expect(response.status).to eq 200
      end

      it 'returns chosen public endpoint' do
        get api("/endpoints/#{e2.id}", different_user)
        expect(e_response).to endpoint_eq e2
      end
    end

    context 'when authenticated as owner' do
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

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        get api("/endpoints/#{e3.id}", developer)
        expect(response.status).to eq 200
      end

      it 'returns owned endpoints in development' do
        get api("/endpoints/#{e3.id}", developer)
        expect(e_response).to endpoint_eq e3
      end
    end
  end


  describe 'POST /endpoints' do
    let(:new_request) do
      {
        endpoint: {
          name: 'Endpoint name',
          description: 'some human description',
          descriptor: '<heavy xml="document">here</heavy>',
          endpoint_type: 'rest',
          invocation_path: 'invocation_path',
          port_mapping_template_id: pmt1.id,
          secured: true
        }
      }
    end

    let(:new_dev_request) do
      {
        endpoint: {
          name: 'Development Endpoint name',
          description: 'some human description',
          descriptor: '',
          endpoint_type: 'rest',
          invocation_path: 'dev_invocation_path',
          port_mapping_template_id: pmt3.id
        }
      }
    end

    let(:wrong_request) do
      {
        endpoint: {
          name: 'Endpoint name',
          description: 'some human description',
          descriptor: '<heavy xml="document">here</heavy>',
          endpoint_type: 'wrong type',
          invocation_path: 'invocation_path',
          port_mapping_template_id: pmt1.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/endpoints"), new_request
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as owner' do
      it 'returns 201 Created on success' do
        post api("/endpoints", user), new_request
        expect(response.status).to eq 201
      end

      it 'creates new endpoint' do
        expect {
          post api("/endpoints", user), new_request
        }.to change { Atmosphere::Endpoint.count }.by(1)
      end

      it 'creates new endpoint with correct attribute values' do
        post api("/endpoints", user), new_request
        expect(e_response['id']).to_not be_nil
        expect(e_response['name']).to eq 'Endpoint name'
        expect(e_response['description']).to eq 'some human description'
        expect(e_response['descriptor']).to eq '<heavy xml="document">here</heavy>'
        expect(e_response['endpoint_type']).to eq 'rest'
        expect(e_response['port_mapping_template_id']).to eq pmt1.id
        expect(e_response['secured']).to eq true
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
        }.to change { Atmosphere::Endpoint.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new endpoint even for not owned port mapping template' do
        expect {
          post api("/endpoints", admin), new_request
          expect(response.status).to eq 201
        }.to change { Atmosphere::Endpoint.count }.by(1)
      end
    end

    context 'when authenticated as developer' do
      it 'returns 201 Success' do
        post api("/endpoints", developer), new_dev_request
        expect(response.status).to eq 201
      end

      it 'creates new development endpoint' do
        expect {
          post api("/endpoints", developer), new_dev_request
          expect(response.status).to eq 201
        }.to change { Atmosphere::Endpoint.count }.by(1)
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

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        put api("/endpoints/#{e1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates endpoint' do
        old_endpoint_type = e1.endpoint_type
        old_port_mapping_template_id = e1.port_mapping_template_id
        put api("/endpoints/#{e1.id}", user), update_json
        updated_e = Atmosphere::Endpoint.find(e1.id)

        expect(updated_e).to be_updated_by_endpoint update_json[:endpoint]
        expect(e_response).to endpoint_eq updated_e
        expect(updated_e.id).to_not be_nil
        expect(updated_e.id).to eq e1.id
        expect(updated_e['description']).to eq 'some human description'
        expect(updated_e['descriptor']).to eq 'nothing'
        expect(updated_e['endpoint_type']).to eq old_endpoint_type
        expect(updated_e['port_mapping_template_id']).to eq old_port_mapping_template_id
      end

      it 'is unable to change assigment to PMT' do
        put api("/endpoints/#{e1.id}", user),
            endpoint: { port_mapping_template_id: pmt2.id }
        e1.reload

        expect(e1.port_mapping_template).to eq pmt1
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

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        put api("/endpoints/#{e3.id}", developer), update_json
        expect(response.status).to eq 200
      end

      it 'returns 403 when updated by not the user who develops given endpoint' do
        put api("/endpoints/#{e3.id}", user), update_json
        expect(response.status).to eq 403
      end

      it 'updates development endpoint' do
        old_endpoint_type = e3.endpoint_type
        old_port_mapping_template_id = e3.port_mapping_template_id
        put api("/endpoints/#{e3.id}", developer), update_json
        updated_e = Atmosphere::Endpoint.find(e3.id)

        expect(updated_e).to be_updated_by_endpoint update_json[:endpoint]
        expect(e_response).to endpoint_eq updated_e
        expect(updated_e.id).to_not be_nil
        expect(updated_e.id).to eq e3.id
        expect(updated_e['description']).to eq 'some human description'
        expect(updated_e['descriptor']).to eq 'nothing'
        expect(updated_e['endpoint_type']).to eq old_endpoint_type
        expect(updated_e['port_mapping_template_id']).to eq old_port_mapping_template_id
      end
    end
  end


  describe 'DELETE /endpoints/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/endpoints/#{e1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        delete api("/endpoints/#{e1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes own endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", user)
        }.to change { Atmosphere::Endpoint.count }.by(-1)
      end

      it 'admin deletes any endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", admin)
        }.to change { Atmosphere::Endpoint.count }.by(-1)
      end

      it 'returns 403 when user tries to delete not owned endpoint' do
        expect {
          delete api("/endpoints/#{e1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { Atmosphere::Endpoint.count }.by(0)
      end
    end

    context 'when authenticated as developer' do
      it 'returns 200 Success' do
        delete api("/endpoints/#{e3.id}", developer)
        expect(response.status).to eq 200
      end

      it 'returns 403 when deleted by not the user who develops given endpoint' do
        expect {
          delete api("/endpoints/#{e3.id}", user)
          expect(response.status).to eq 403
        }.to change { Atmosphere::Endpoint.count }.by(0)
      end

      it 'deletes development endpoint' do
        expect {
          delete api("/endpoints/#{e3.id}", developer)
        }.to change { Atmosphere::Endpoint.count }.by(-1)
      end
    end
  end

  describe 'GET /endpoints/:id/descriptor' do
    let(:at1) { create(:appliance_type, visible_to: :all) }
    let(:pmt_at1) { create(:port_mapping_template, appliance_type: at1) }
    let(:all_endpoint) { create(:endpoint, invocation_path: 'invocation/path', descriptor: 'payload', port_mapping_template: pmt_at1) }

    let(:at2) { create(:appliance_type, visible_to: :owner, author: user) }
    let(:pmt_at2) { create(:port_mapping_template, appliance_type: at2) }
    let(:owner_endpoint) { create(:endpoint, invocation_path: 'invocation/path', descriptor: 'payload', port_mapping_template: pmt_at2) }

    let(:endpoint_with_descriptor_url) { create(:endpoint, invocation_path: 'invocation/path', descriptor: 'payload #{descriptor_url}', port_mapping_template: pmt_at2) }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error for not visible for all appliance types' do
        get api("/endpoints/#{owner_endpoint.id}/descriptor")
        expect(response.status).to eq 401
      end

      it 'returns 200 Success' do
        get api("/endpoints/#{all_endpoint.id}/descriptor")
        expect(response.status).to eq 200
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/endpoints/#{owner_endpoint.id}/descriptor", user)
        expect(response.status).to eq 200
      end

      it 'returns endpoint descriptor' do
        get api("/endpoints/#{owner_endpoint.id}/descriptor", user)
        expect(response.body).to eq owner_endpoint.descriptor
      end

      it 'return 404 Not Found when endpoint does not exist' do
        get api("/endpoints/not_existing/descriptor", user)
        expect(response.status).to eq 404
      end

      it 'returns 403 Forbidden when user has not right to see appliance type' do
        get api("/endpoints/#{owner_endpoint.id}/descriptor", different_user)
        expect(response.status).to eq 403
      end

      it 'returns descriptor with #{descriptor_url} filled in' do
        get api("/endpoints/#{endpoint_with_descriptor_url.id}/descriptor", user)
        expect(response.body).to eq "payload http://www.example.com/api/v1/endpoints/#{endpoint_with_descriptor_url.id}/descriptor"
      end

      it 'returns empty descriptor' do
        @empty_endpoint = create(:endpoint, descriptor: nil, port_mapping_template: pmt_at2)
        get api("/endpoints/#{@empty_endpoint.id}/descriptor", user)

        expect(response.body).to eq ''
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
