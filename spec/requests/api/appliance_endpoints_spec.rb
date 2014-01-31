require 'spec_helper'

describe Api::V1::ApplianceEndpointsController do
  include ApiHelpers

  before do
    @user = create(:user)

    @at_without_endpoints = create(:appliance_type, visible_to: :all)
    @at_with_web          = create(:appliance_type, visible_to: :all)
    @at_with_web_and_rest = create(:appliance_type, visible_to: :all)

    @web_pmt      = create(:port_mapping_template, application_protocol: :http, appliance_type: @at_with_web)
    @web_rest_pmt = create(:port_mapping_template, application_protocol: :http, appliance_type: @at_with_web_and_rest)

    @web_endpoint1 = create(:endpoint, name: 'webapp1', endpoint_type: :webapp, port_mapping_template: @web_pmt)
    @web_endpoint2 = create(:endpoint, name: 'webapp1', endpoint_type: :webapp, port_mapping_template: @web_rest_pmt)
    @rest_endpoint = create(:endpoint, name: 'rest', endpoint_type: :rest, port_mapping_template: @web_rest_pmt)
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
          expect(endpoints_response.size).to eq 2
        end

        it 'returns information about name and description' do
          expect(endpoints_response[0]).to basic_appliance_type_eq @at_with_web
          expect(endpoints_response[1]).to basic_appliance_type_eq @at_with_web_and_rest
        end

        it 'returns information about endpoints' do
          expect(endpoints(endpoints_response[0])[0]).to basic_endpoint_eq @web_endpoint1
          expect(endpoints(endpoints_response[1])[0]).to basic_endpoint_eq @web_endpoint2
          expect(endpoints(endpoints_response[1])[1]).to basic_endpoint_eq @rest_endpoint
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