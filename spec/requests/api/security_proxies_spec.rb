require 'spec_helper'

describe API::SecurityProxies do
  include ApiHelpers

  let(:owner1) { create(:user) }
  let(:owner2) { create(:user) }
  let!(:proxy1) { create(:security_proxy, name: 'first/proxy', users: [owner1, owner2]) }
  let!(:proxy2) { create(:security_proxy, name: 'second/proxy', users: [owner1]) }

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

  describe 'GET /security_proxies/proxy/name' do
    it 'returns 200 on success' do
      get api('/security_proxies/first/proxy')
      expect(response.status).to eq 200
    end

    it 'returns security proxy' do
      get api('/security_proxies/first/proxy')
      expect(json_response).to proxy_eq proxy1
    end

    it 'return 404 Not Found on proxy not found' do
      get api('/security_proxies/non/existing/sec/proxy')
      expect(response.status).to eq 404
    end
  end

  describe 'GET /security_proxies/proxy/name/payload' do
    it 'returns 200 on success' do
      get api('/security_proxies/first/proxy/payload')
      expect(response.status).to eq 200
    end

    it 'returns security proxy payload' do
      get api('/security_proxies/first/proxy/payload')
      expect(response.content_type).to eq 'text/plain'
      expect(response.body).to eq proxy1.payload
    end

    it 'return 404 Not Found on proxy not found' do
      get api('/security_proxies/non/existing/sec/proxy/payload')
      expect(response.status).to eq 404
    end
  end

  describe 'POST /security_proxies' do
    let(:new_proxy) { {name: 'new/proxy', payload: 'payload'} }
    let(:new_proxy_with_owners) { {name: 'new/proxy/with/owners', payload: 'payload', owners: [owner1.login, owner2.login]}}

    context 'when unauthenticated' do
      it 'returns 401 authentication error' do
        post api("/security_proxies")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 201 Created on new security proxy created' do
        post api("/security_proxies", owner1), new_proxy
        expect(response.status).to eq 201
      end

      it 'creates new security proxy' do
        expect {
          post api("/security_proxies", owner1), new_proxy
        }.to change { SecurityProxy.count }.by(1)
      end

      it 'creates new security proxy with owner set to user' do
        post api("/security_proxies", owner1), new_proxy
        expect(SecurityProxy.find_by(name: new_proxy[:name]).users).to include owner1
      end

      it 'creates new security with given owner list' do
        post api("/security_proxies", owner1), new_proxy_with_owners
        created_proxy = SecurityProxy.find_by(name: new_proxy_with_owners[:name])
        expect(created_proxy.users).to include owner1
        expect(created_proxy.users).to include owner2
      end

      it 'returns 400 Bad Request when name is missing' do
        post api("/security_proxies", owner1), {payload: 'payload'}
        expect(response.status).to eq 400
      end

      it 'returns 400 Bad Request when name format is incorect' do
        post api("/security_proxies", owner1), {name: 'wrong\name'}
        expect(response.status).to eq 400
      end

      it 'returns 400 Bad Request when payload is missing' do
        post api("/security_proxies", owner1), {name: 'new/proxy'}
        expect(response.status).to eq 400
      end
    end
  end

  describe 'PUT /security_proxies/proxy/name' do
    context 'when unauthenticated' do
      it 'returns 401 authentication error' do
        put api("/security_proxies/#{proxy1.name}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        put api("/security_proxies/#{proxy1.name}", owner1)
        expect(response.status).to eq 200
      end

      it 'updates security proxy payload' do
        new_payload = 'new payload'
        put api("/security_proxies/#{proxy1.name}", owner1), {payload: new_payload}
        expect(json_response['payload']).to eq new_payload
      end

      it 'updates security proxy owners' do
        new_payload = 'new payload'
        put api("/security_proxies/#{proxy1.name}", owner1), {owners: [owner2.login]}
        updated_proxy = SecurityProxy.find(proxy1.id)
        expect(updated_proxy.users).to include owner2
        expect(updated_proxy.users).to_not include owner1
      end

      it 'returns 404 on security proxy not found' do
        put api("/security_proxies/non/existing", owner1)
        expect(response.status).to eq 404
      end

      it 'returns 403 Forbidden when user is not policy owner' do
        put api("/security_proxies/#{proxy2.name}", owner2)
        expect(response.status).to eq 403
      end
    end
  end

  describe 'DELETE /security_proxies/proxy/name' do
    context 'when unauthenticated' do
      it 'returns 401 authentication error' do
        delete api("/security_proxies/#{proxy2.name}")
        expect(response.status).to eq 401
      end

       context 'when authenticated as user' do
        it 'returns 200 on success' do
          delete api("/security_proxies/#{proxy2.name}", owner1)
          expect(response.status).to eq 200
        end

        it 'returns 403 Forbidden when user is not policy owner' do
          delete api("/security_proxies/#{proxy2.name}", owner2)
          expect(response.status).to eq 403
        end
      end
    end
  end
end