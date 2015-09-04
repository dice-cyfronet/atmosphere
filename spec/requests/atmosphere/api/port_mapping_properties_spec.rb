require 'rails_helper'

describe Atmosphere::Api::V1::PortMappingPropertiesController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let!(:at1) { create(:filled_appliance_type, author: user, visible_to: 'owner') }
  let!(:at2) { create(:appliance_type, author: user, visible_to: 'all') }
  let!(:pmt1) { create(:port_mapping_template, appliance_type: at1) }
  let!(:pmt2) { create(:port_mapping_template, appliance_type: at2) }

  let!(:pmp1) { create(:pmt_property, port_mapping_template: pmt1) }
  let!(:pmp1b) { create(:pmt_property, port_mapping_template: pmt1) }
  let!(:pmp2) { create(:pmt_property, port_mapping_template: pmt2) }


  describe 'GET /port_mapping_properties' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden error' do
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt1.id}", different_user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns owned port_mapping_properties' do
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt1.id}", user)
        expect(pmps_response).to be_an Array
        expect(pmps_response.size).to eq 2
        expect(pmps_response).to match_array [pmp_json(pmp1), pmp_json(pmp1b)]
      end

      it 'returns public port_mapping_properties' do
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt2.id}", user)
        expect(pmps_response).to be_an Array
        expect(pmps_response.size).to eq 1
        expect(pmps_response[0]).to port_mapping_property_eq pmp2
        get api("/port_mapping_properties?port_mapping_template_id=#{pmt2.id}", different_user)
        expect(pmps_response).to be_an Array
        expect(pmps_response.size).to eq 1
        expect(pmps_response[0]).to port_mapping_property_eq pmp2
      end
    end

    def pmp_json(pmp)
      pmp.as_json(except: [:created_at, :updated_at, :tenant_id]).tap do |hsh|
        hsh['compute_site_id'] = pmp.tenant_id
      end
    end
  end


  describe 'GET /port_mapping_properties/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mapping_properties/#{pmp1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as not owner and not admin' do
      it 'returns 403 Forbidden error for not public resources' do
        get api("/port_mapping_properties/#{pmp1.id}", different_user)
        expect(response.status).to eq 403
      end

      it 'returns 200 Success for public resources' do
        get api("/port_mapping_properties/#{pmp2.id}", different_user)
        expect(response.status).to eq 200
      end

      it 'returns chosen public port mapping property' do
        get api("/port_mapping_properties/#{pmp2.id}", different_user)
        expect(pmp_response).to port_mapping_property_eq pmp2
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        get api("/port_mapping_properties/#{pmp1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns chosen owned port mapping property' do
        get api("/port_mapping_properties/#{pmp1.id}", user)
        expect(pmp_response).to port_mapping_property_eq pmp1
      end

      it 'returns chosen public port mapping property' do
        get api("/port_mapping_properties/#{pmp2.id}", user)
        expect(pmp_response).to port_mapping_property_eq pmp2
        get api("/port_mapping_properties/#{pmp2.id}", different_user)
        expect(pmp_response).to port_mapping_property_eq pmp2
      end

      it 'returns 404 Not Found when port mapping property is not found' do
        get api("/port_mapping_properties/non_existing", user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'returns any chosen port mapping property' do
        get api("/port_mapping_properties/#{pmp1.id}", admin)
        expect(pmp_response).to port_mapping_property_eq pmp1
        get api("/port_mapping_properties/#{pmp2.id}", admin)
        expect(pmp_response).to port_mapping_property_eq pmp2
      end
    end
  end


  describe 'POST /port_mapping_properties' do
    let(:new_request) do
      {
          port_mapping_property: {
              key: 'some:key',
              value: 'DOING_THE_PROPER_THING',
              port_mapping_template_id: pmt1.id
          }
      }
    end

    let(:wrong_request) do
      {
          port_mapping_property: {
              key: nil,
              value: 'TRYING_TO_DO_THE_IMPROPER_THING',
              port_mapping_template_id: pmt1.id
          }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/port_mapping_properties"), new_request
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as owner' do
      it 'returns 201 Created on success' do
        post api("/port_mapping_properties", user), new_request
        expect(response.status).to eq 201
      end

      it 'creates new port mapping property' do
        expect {
          post api("/port_mapping_properties", user), new_request
        }.to change { Atmosphere::PortMappingProperty.count }.by(1)
      end

      it 'creates new port mapping property with correct attribute values' do
        post api("/port_mapping_properties", user), new_request
        expect(pmp_response['id']).to_not be_nil
        expect(pmp_response['key']).to eq 'some:key'
        expect(pmp_response['value']).to eq 'DOING_THE_PROPER_THING'
        expect(pmp_response['port_mapping_template_id']).to eq pmt1.id
      end

      it 'returns 422 when port mapping property field is wrong' do
        post api("/port_mapping_properties", user), wrong_request
        expect(response.status).to eq 422
      end

      it 'returns 403 Forbidden when creating port mapping property for not owned port mapping template' do
        post api("/port_mapping_properties", different_user), new_request
        expect(response.status).to eq 403
      end

      it 'does not create new port mapping property for not owned port mapping template' do
        expect {
          post api("/port_mapping_properties", different_user), new_request
        }.to change { Atmosphere::PortMappingProperty.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'creates new port mapping property even for not owned port mapping template' do
        expect {
          post api("/port_mapping_properties", admin), new_request
          expect(response.status).to eq 201
        }.to change { Atmosphere::PortMappingProperty.count }.by(1)
      end
    end

  end


  describe 'PUT /port_mapping_properties/:id' do

    let(:update_json) do {port_mapping_property: {
        value: 'OTHER_THING'
    }} end

    let(:wrong_update_json) do {port_mapping_property: {
        value: nil
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/port_mapping_properties/#{pmp1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        put api("/port_mapping_properties/#{pmp1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates port mapping property' do
        old_key = pmp1.key
        old_port_mapping_template_id = pmp1.port_mapping_template_id
        put api("/port_mapping_properties/#{pmp1.id}", user), update_json
        updated_e = Atmosphere::PortMappingProperty.find(pmp1.id)

        expect(updated_e).to be_updated_by_port_mapping_property update_json[:port_mapping_property]
        expect(pmp_response).to port_mapping_property_eq updated_e
        expect(updated_e.id).to_not be_nil
        expect(updated_e.id).to eq pmp1.id
        expect(updated_e['value']).to eq 'OTHER_THING'
        expect(updated_e['key']).to eq old_key
        expect(updated_e['port_mapping_template_id']).to eq old_port_mapping_template_id
      end

      it 'is not able to update PMT' do
        put api("/port_mapping_properties/#{pmp1.id}", user),
            port_mapping_property: { port_mapping_template_id: pmt2.id }
        pmp1.reload

        expect(pmp1.port_mapping_template).to eq pmt1
      end

      it 'admin is able to update any port mapping property' do
        put api("/port_mapping_properties/#{pmp1.id}", admin), update_json
        expect(response.status).to eq 200
      end

      it 'returns 422 when port mapping property key is wrong' do
        put api("/port_mapping_properties/#{pmp1.id}", user), wrong_update_json
        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not the parent appliance type owner' do
        put api("/port_mapping_properties/#{pmp1.id}", different_user), update_json
        expect(response.status).to eq 403
      end
    end
  end


  describe 'DELETE /port_mapping_properties/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/port_mapping_properties/#{pmp1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as owner' do
      it 'returns 200 Success' do
        delete api("/port_mapping_properties/#{pmp1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes own port mapping property' do
        expect {
          delete api("/port_mapping_properties/#{pmp1.id}", user)
        }.to change { Atmosphere::PortMappingProperty.count }.by(-1)
      end

      it 'admin deletes any port mapping property' do
        expect {
          delete api("/port_mapping_properties/#{pmp1.id}", admin)
        }.to change { Atmosphere::PortMappingProperty.count }.by(-1)
      end

      it 'returns 403 when user tries to delete not owned port mapping property' do
        expect {
          delete api("/port_mapping_properties/#{pmp1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { Atmosphere::PortMappingProperty.count }.by(0)
      end
    end
  end

  def pmps_response
    json_response['port_mapping_properties']
  end

  def pmp_response
    json_response['port_mapping_property']
  end

end
