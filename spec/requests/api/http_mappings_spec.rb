require 'rails_helper'

describe Api::V1::HttpMappingsController do

  include ApiHelpers

  describe 'GET /http_mappings' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/http_mappings")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        user = create(:user)

        get api("/http_mappings", user)
        expect(response.status).to eq 200
      end
      it 'returns mappings' do
        user = create(:user)
        hm1 = user_http_mapping(user)
        hm2 = user_http_mapping(user)

        get api('/http_mappings', user)
        expect(hms_response).to be_an Array
        expect(hms_response.size).to eq 2
        expect(hms_response[0]).to http_mapping_eq hm1
        expect(hms_response[1]).to http_mapping_eq hm2
      end

      it 'gets only owned mappings' do
        user_http_mapping(create(:user))
        second_user = create(:user)
        hm = user_http_mapping(second_user)

        get api('/http_mappings', second_user)
        expect(hms_response).to be_an Array
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm
      end

      context 'filter params' do
        it 'finds only mapping with requested id' do
          user = create(:user)
          hm1 = user_http_mapping(user)
          hm2 = user_http_mapping(user)

          get api("/http_mappings?id=#{hm1.id}", user)

          expect(hms_response).to be_an Array
          expect(hms_response.size).to eq 1
          expect(hms_response[0]).to http_mapping_eq hm1
        end
        it 'gets only its mappings' do
          user = create(:user)
          hm1 = user_http_mapping(user)
          hm2 = user_http_mapping(user)

          get api("/http_mappings?appliance_id=#{hm1.appliance_id}", user)
          expect(hms_response).to be_an Array
          expect(hms_response.size).to eq 1
          expect(hms_response[0]).to http_mapping_eq hm1
        end
      end
    end
  end

  describe 'GET /http_mappings/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        hm = create(:http_mapping)

        get api("/http_mappings/#{hm.id}")
        expect(response.status).to eq 401
      end
    end
    context 'when authenticated as user' do
      it 'returns 200 on success' do
        user = create(:user)
        hm = user_http_mapping(user)

        get api("/http_mappings/#{hm.id}", user)

        expect(response.status).to eq 200
        expect(hm_response).to http_mapping_eq hm
      end
    end
  end

  describe 'GET /http_mappings?appliance_id={id}' do
    context 'when query for exisitng appliance' do
      it 'gets the only mapping that fits the query' do
        user = create(:user)
        user_http_mapping(user)
        hm = user_http_mapping(user)

        get api("/http_mappings?appliance_id=#{hm.appliance_id}", user)
        expect(response.status).to eq 200
        expect(hms_response.size).to eq 1
        expect(hms_response[0]).to http_mapping_eq hm
      end
    end
    context 'when query for non existing appliance' do
      it 'gets empty answer' do
        user = create(:user)

        get api("/http_mappings?appliance_id=-666", user)
        expect(response.status).to eq 200
        expect(hms_response.size).to eq 0
      end
    end
  end

  describe 'PUT /http_mappings/{id}' do
    it 'return 401 for not authenticated user' do
      hm = create(:http_mapping)

      put api("/http_mappings/#{hm.id}")
      expect(response.status).to eq 401
    end

    it 'sets custom mapping name for owner' do
      user = create(:user)
      hm = user_http_mapping(user)
      update_request = {
        http_mapping: { custom_name: 'custom_name' }
      }

      put api("/http_mappings/#{hm.id}", user), update_request
      hm.reload

      expect(response.status).to eq 200
      expect(hm.custom_name).to eq 'custom_name'
    end
  end

  def hms_response
    json_response['http_mappings']
  end

  def hm_response
    json_response['http_mapping']
  end

  def user_http_mapping(user)
    as = create(:appliance_set, user: user)
    appl = create(:appliance, appliance_set: as)

    create(:http_mapping, appliance: appl)
  end
end