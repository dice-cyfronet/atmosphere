require 'spec_helper'

describe Api::V1::HttpMappingsController do

  include ApiHelpers

  let(:user)  { create(:user) }

  let(:as1) { create(:appliance_set, user: user) }
  let(:appl1) { create(:appliance, appliance_set: as1) }
  let!(:hm1) { create(:http_mapping, appliance: appl1) }

  let(:as2) { create(:appliance_set, user: user) }
  let(:appl2) { create(:appliance, appliance_set: as2) }
  let!(:hm2) { create(:http_mapping, appliance: appl2) }

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
    context 'when exist other users mappings' do
      let(:user_a)  { create(:user) }
      let(:as_a) { create(:appliance_set, user: user_a) }
      let(:appl_a) { create(:appliance, appliance_set: as_a) }
      let!(:hm_a) { create(:http_mapping, appliance: appl_a) }
      it 'gets only its mappings' do
        get api('/http_mappings', user_a)
        expect(hms_response).to be_an Array
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm_a
      end
    end

    context 'when filter params speciffied' do
      let(:user_a)  { create(:user) }
      let(:as_a) { create(:appliance_set, user: user_a) }
      let(:appl_a) { create(:appliance, appliance_set: as_a) }
      let(:appl_a2) { create(:appliance, appliance_set: as_a) }
      let!(:hm_a) { create(:http_mapping, appliance: appl_a) }
      let!(:hm_a2) { create(:http_mapping, appliance: appl_a2) }
      it 'finds only mapping with requested id' do
        get api("/http_mappings?id=#{hm_a2.id}", user_a)
        expect(hms_response).to be_an Array

        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm_a2
      end
      it 'gets only its mappings' do
        get api("/http_mappings?appliance_id=#{appl_a.id}", user_a)
        expect(hms_response).to be_an Array
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm_a
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

  describe 'GET /http_mappings?appliance_id={id}' do
    context 'when query for exisitng appliance' do
      it 'gets the only mapping that fits the query' do
        get api("/http_mappings?appliance_id=#{hm1.appliance_id}", user)
        expect(response.status).to eq 200
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm1
      end
    end
    context 'when query for non existing appliance' do
      it 'gets empty answer' do
        get api("/http_mappings?appliance_id=666", user)
        expect(response.status).to eq 200
        expect(hms_response.size).to eq 0
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