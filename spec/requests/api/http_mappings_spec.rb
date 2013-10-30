require 'spec_helper'

describe Api::V1::HttpMappingsController do

  include ApiHelpers

  let(:user)  { create(:user) }

  let!(:hm1) { create(:http_mapping) }
  let!(:hm2) { create(:http_mapping) }

  describe 'GET /http_mappings' do

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/http_mappings")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/http_mappings", user)
        expect(response.status).to eq 200
      end
      it 'returns mappings' do
        get api('/http_mappings', user)
        expect(hms_response).to be_an Array
        expect(hms_response.size).to eq 2
        expect(hms_response[0]).to http_mapping_eq hm1
        expect(hms_response[1]).to http_mapping_eq hm2
      end
    end

    context 'when query for speciffic appliance' do
      it 'returns 200 on success' do
        get api("/http_mappings?appliance_id=#{hm1.appliance_id}", user)
        expect(response.status).to eq 200
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm1
      end
    end

  end

  describe 'GET /http_mappings/{id}' do

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/http_mappings/#{hm1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/http_mappings/#{hm1.id}", user)
        expect(response.status).to eq 200
        expect(hm_response).to http_mapping_eq hm1
      end
    end

  end

  def hms_response
    json_response['http_mappings']
  end

  def hm_response
    json_response['http_mapping']
  end

end