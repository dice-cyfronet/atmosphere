require 'rails_helper'

describe Atmosphere::Api::V1::TenantsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:t1) { create(:tenant, site_type: :private) }
  let!(:t2) { create(:tenant, site_type: :private) }
  let!(:t3) { create(:tenant, site_type: :public) }

  describe 'GET /tenants' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/tenants")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/tenants", user)
        expect(response.status).to eq 200
      end

      it 'returns only basic tenant information' do
        get api("/tenants", user)
        expect(ts_response).to be_an Array
        expect(ts_response.size).to eq 3
        expect(ts_response[0]).to tenant_basic_eq t1
        expect(ts_response[1]).to tenant_basic_eq t2
        expect(ts_response[2]).to tenant_basic_eq t3
      end

      context 'search' do
        it 'returns only public tenants' do
          get api("/tenants?site_type=private", user)
          expect(ts_response.size).to eq 2
          expect(ts_response[0]).to tenant_basic_eq t1
          expect(ts_response[1]).to tenant_basic_eq t2
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns full tenant information' do
        get api("/tenants", admin)
        expect(ts_response.size).to eq 3
        expect(ts_response[0]).to tenant_full_eq t1
        expect(ts_response[1]).to tenant_full_eq t2
        expect(ts_response[2]).to tenant_full_eq t3
      end
    end
  end

  describe 'GET /tenants/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/tenants/#{t1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/tenants", user)
        expect(response.status).to eq 200
      end

      it 'returns only basic tenant information' do
        get api("/tenants/#{t1.id}", user)
        expect(t_response).to tenant_basic_eq t1
      end

      it 'returns 404 (Not Found) on nonexistent tenant' do
        get api("/tenants/nonexisting", user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'return full tenant information' do
        get api("/tenants/#{t1.id}", admin)
        expect(t_response).to tenant_full_eq t1
      end
    end
  end

  def ts_response
    json_response['tenants']
  end

  def t_response
    json_response['tenant']
  end
end