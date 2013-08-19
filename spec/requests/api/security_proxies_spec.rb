require 'spec_helper'

describe API::SecurityProxies do
  include ApiHelpers

  let(:owner1) { create(:user) }
  let(:owner2) { create(:user) }
  let!(:proxy1) { create(:security_proxy, name: 'first/proxy', users: [owner1, owner2]) }
  let!(:proxy2) { create(:security_proxy, name: 'second/proxy') }

  describe 'GET /security_proxies' do
    it 'returns 200 on success' do
      get api('/security_proxies')
      expect(response.status).to eq 200
    end

    it 'returns security proxies array' do
      get api('/security_proxies')
      expect(response.status).to eq 200
      expect(json_response).to be_an Array
      expect(json_response.size).to eq 2

      expect(json_response[0]).to proxy_eq proxy1
      expect(json_response[1]).to proxy_eq proxy2
    end
  end
end