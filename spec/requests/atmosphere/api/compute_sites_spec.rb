require 'rails_helper'

describe Api::V1::ComputeSitesController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:cs1) { create(:compute_site, site_type: :private) }
  let!(:cs2) { create(:compute_site, site_type: :private) }
  let!(:cs3) { create(:compute_site, site_type: :public) }

  describe 'GET /compute_sites' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/compute_sites")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/compute_sites", user)
        expect(response.status).to eq 200
      end

      it 'returns only basic compute site informations' do
        get api("/compute_sites", user)
        expect(cses_response).to be_an Array
        expect(cses_response.size).to eq 3
        expect(cses_response[0]).to compute_site_basic_eq cs1
        expect(cses_response[1]).to compute_site_basic_eq cs2
        expect(cses_response[2]).to compute_site_basic_eq cs3
      end

      context 'search' do
        it 'returns only public compute sites' do
          get api("/compute_sites?site_type=private", user)
          expect(cses_response.size).to eq 2
          expect(cses_response[0]).to compute_site_basic_eq cs1
          expect(cses_response[1]).to compute_site_basic_eq cs2
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns full compute sites information' do
        get api("/compute_sites", admin)
        expect(cses_response.size).to eq 3
        expect(cses_response[0]).to compute_site_full_eq cs1
        expect(cses_response[1]).to compute_site_full_eq cs2
        expect(cses_response[2]).to compute_site_full_eq cs3
      end
    end
  end

  describe 'GET /compute_sites/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/compute_sites/#{cs1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/compute_sites", user)
        expect(response.status).to eq 200
      end

      it 'returns only basic compute site informations' do
        get api("/compute_sites/#{cs1.id}", user)
        expect(cs_response).to compute_site_basic_eq cs1
      end

      it 'returns 404 (Not Found) on non existing compute site' do
        get api("/compute_sites/nonexisting", user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'return full compute site information' do
        get api("/compute_sites/#{cs1.id}", admin)
        expect(cs_response).to compute_site_full_eq cs1
      end
    end
  end

  def cses_response
    json_response['compute_sites']
  end

  def cs_response
    json_response['compute_site']
  end
end