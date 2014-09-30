require 'rails_helper'

describe Atmosphere::Api::V1::ApplianceEndpointsController do
  include ApiHelpers

  before do
    @user = create(:user)

    @at_without_endpoints = create(:appliance_type, visible_to: :all)
    @at_with_web          = create(:appliance_type, visible_to: :all)
    @at_with_web_and_rest = create(:appliance_type, visible_to: :all)
    @at_with_web_and_ws   = create(:appliance_type, visible_to: :all)

    @web_pmt      = create(:port_mapping_template, application_protocol: :http, appliance_type: @at_with_web)
    @web_rest_pmt = create(:port_mapping_template, application_protocol: :http, appliance_type: @at_with_web_and_rest)
    @web_ws_pmt = create(:port_mapping_template, application_protocol: :http, appliance_type: @at_with_web_and_ws)

    @web_endpoint1 = create(:endpoint, name: 'webapp1', endpoint_type: :webapp, port_mapping_template: @web_pmt)

    @web_endpoint2 = create(:endpoint, name: 'webapp2', endpoint_type: :webapp, port_mapping_template: @web_rest_pmt)
    @rest_endpoint = create(:endpoint, name: 'rest', endpoint_type: :rest, port_mapping_template: @web_rest_pmt)

    @web_endpoint3 = create(:endpoint, name: 'webapp3', endpoint_type: :webapp, port_mapping_template: @web_ws_pmt)
    @ws_endpoint = create(:endpoint, name: 'ws', endpoint_type: :ws, port_mapping_template: @web_ws_pmt)
  end

  describe 'GET /appliance_endpoints' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_endpoints')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/appliance_endpoints', @user)
        expect(response.status).to eq 200
      end

      context 'and we are interested in all endpoints' do
        before { get api('/appliance_endpoints', @user) }

        it 'returns only appliance types with endpoints' do
          expect(endpoints_response.size).to eq 3
        end

        it 'returns information about name and description' do
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web
          expect(endpoints_response[1]).to basic_appliance_type_eq @at_with_web_and_rest
          expect(endpoints_response[2]).to basic_appliance_type_eq @at_with_web_and_ws
        end

        it 'returns information about endpoints' do
          expect(endpoints(endpoints_response[0])[0]).to basic_endpoint_eq @web_endpoint1
          expect(endpoints(endpoints_response[1])[0]).to basic_endpoint_eq @web_endpoint2
          expect(endpoints(endpoints_response[1])[1]).to basic_endpoint_eq @rest_endpoint
          expect(endpoints(endpoints_response[2])[0]).to basic_endpoint_eq @web_endpoint3
          expect(endpoints(endpoints_response[2])[1]).to basic_endpoint_eq @ws_endpoint
        end
      end

      context 'and we are interested only in REST endpoints' do
        before { get api('/appliance_endpoints?endpoint_type=rest', @user) }

        it 'returns only appliance types with endpoints' do
          expect(endpoints_response.size).to eq 1
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web_and_rest
        end

        it 'returns only REST endpoints' do
          expect(endpoints(endpoints_response[0]).size).to eq 1
          expect(endpoints(endpoints_response[0])[0]).to basic_endpoint_eq @rest_endpoint
        end
      end

      context 'and we are interested only in WS endpoints' do
        before { get api('/appliance_endpoints?endpoint_type=ws', @user) }

        it 'returns only appliance types with endpoints' do
          expect(endpoints_response.size).to eq 1
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web_and_ws
        end
      end

      context 'and we are interested in WebApp and WS endpoints' do
        before { get api('/appliance_endpoints?endpoint_type=ws,webapp', @user) }

        it 'returns appliance types with WebApp and WS endpoints' do
          expect(endpoints_response.size).to eq 3
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web
          expect(endpoints_response[1]).to basic_appliance_type_eq @at_with_web_and_rest
          expect(endpoints_response[2]).to basic_appliance_type_eq @at_with_web_and_ws
        end

        it 'returns only WebApp and WS endpoints' do
          expect(endpoints(endpoints_response[1]).size).to eq 1
          expect(endpoints(endpoints_response[1])[0]).to basic_endpoint_eq @web_endpoint2

          expect(endpoints(endpoints_response[2]).size).to eq 2
          expect(endpoints(endpoints_response[2])[0]).to basic_endpoint_eq @web_endpoint3
          expect(endpoints(endpoints_response[2])[1]).to basic_endpoint_eq @ws_endpoint
        end
      end

      context 'and we want to see only AT with selected endpoints' do
        it 'returns single appliance type' do
          get api("/appliance_endpoints?endpoint_id=#{@web_endpoint2.id}", @user)
          expect(endpoints_response.size).to eq 1
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web_and_rest
        end
      end
    end
  end

  def endpoints_response
    json_response['appliance_endpoints']
  end

  def endpoints(endpoint_response)
    endpoint_response['endpoints']
  end
end