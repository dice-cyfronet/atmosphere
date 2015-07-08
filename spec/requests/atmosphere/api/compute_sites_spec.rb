require 'rails_helper'

describe Atmosphere::Api::V1::ComputeSitesController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:t1) { create(:tenant, tenant_type: :private) }
  let!(:t2) { create(:tenant, tenant_type: :private) }
  let!(:t3) { create(:tenant, tenant_type: :public) }

  let!(:f1) { create(:fund, users: [admin, user], tenants: [t1, t2, t3]) }

  describe 'GET /compute_sites' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/compute_sites")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/compute_sites', user)
        expect(response.status).to eq 200
      end

      it 'returns only basic compute site information' do
        get api('/compute_sites', user)
        expect(ts_response).to be_an Array
        expect(ts_response.size).to eq 3
        expect(ts_response[0]).to compute_site_basic_eq t1
        expect(ts_response[1]).to compute_site_basic_eq t2
        expect(ts_response[2]).to compute_site_basic_eq t3
      end

      it 'finds only those tenants which the user is authorized to access' do
        f1.tenants = [t1, t3]
        get api('/compute_sites', user)
        expect(ts_response).to be_an Array
        expect(ts_response.size).to eq 2
        expect(ts_response[0]).to compute_site_basic_eq t1
        expect(ts_response[1]).to compute_site_basic_eq t3
      end

      context 'search' do
        it 'returns only private compute sites' do
          get api('/compute_sites?site_type=private', user)
          expect(ts_response.size).to eq 2
          expect(ts_response[0]).to compute_site_basic_eq t1
          expect(ts_response[1]).to compute_site_basic_eq t2
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns full compute site information' do
        get api('/compute_sites', admin)
        expect(ts_response.size).to eq 3
        expect(ts_response[0]).to compute_site_full_eq t1
        expect(ts_response[1]).to compute_site_full_eq t2
        expect(ts_response[2]).to compute_site_full_eq t3
      end
    end
  end

  describe 'GET /compute_sites/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/compute_sites/#{t1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/compute_sites', user)
        expect(response.status).to eq 200
      end

      it 'returns only basic compute site information' do
        get api("/compute_sites/#{t1.id}", user)
        expect(t_response).to compute_site_basic_eq t1
      end

      it 'returns 404 (Not Found) on nonexistent compute site' do
        get api('/compute_sites/nonexisting', user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'return full compute site information' do
        get api("/compute_sites/#{t1.id}", admin)
        expect(t_response).to compute_site_full_eq t1
      end
    end
  end

  def ts_response
    json_response['compute_sites']
  end

  def t_response
    json_response['compute_site']
  end
end
