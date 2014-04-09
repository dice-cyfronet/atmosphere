require 'spec_helper'

describe Api::V1::VirtualMachineFlavorsController do
  include ApiHelpers

  let(:user) { create(:user) }

  describe 'GET /virtual_machine_flavors' do

    context 'when not authenticated' do

      it 'returns 401 Unauthorized error' do
          get api('/virtual_machine_flavors')
          expect(response.status).to eq 401
        end

    end

    context 'when authenticated' do

      let!(:f1) { create(:virtual_machine_flavor) }
      let!(:f2) { create(:virtual_machine_flavor) }

      it 'returns 200' do
        get api('/virtual_machine_flavors', user)
        expect(response.status).to eq 200
      end

      it 'returns all flavors when no filters are specified' do
        get api('/virtual_machine_flavors', user)
        flavors = fls_response
        expect(flavors.size).to eq 2
      end

      context 'when filter' do

      end

    end

  end

  def fls_response
    json_response['virtual_machine_flavors']
  end

end