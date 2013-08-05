require 'spec_helper'

describe API::Workflows do
  include ApiHelpers

  let(:user) { create(:user) }

  describe 'GET /workflows' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/workflows')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/workflows', user)
        expect(response.status).to eq 200
      end
    end
  end
end