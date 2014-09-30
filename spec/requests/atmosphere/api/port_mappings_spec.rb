require 'rails_helper'

describe Atmosphere::Api::V1::PortMappingsController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin)  { create(:admin) }

  let(:user_as) { create(:appliance_set, user: user) }
  let(:appl) { create(:appliance, appliance_set: user_as) }
  let(:vm1) { create(:virtual_machine, appliances: [ appl ]) }
  let(:vm2) { create(:virtual_machine, appliances: [ appl ]) }

  let!(:pm1) { create(:port_mapping, virtual_machine: vm1) }
  let!(:pm2) { create(:port_mapping, virtual_machine: vm2) }
  let!(:other_user_pm) { create(:port_mapping) }

  describe 'GET /port_mappings' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mappings")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/port_mappings", user)
        expect(response.status).to eq 200
      end

      it 'returns port mappings' do
        get api("/port_mappings", user)
        expect(pms_response).to be_an Array
        expect(pms_response.size).to eq 2
        expect(pms_response[0]).to port_mapping_eq pm1
        expect(pms_response[1]).to port_mapping_eq pm2
      end

      context 'search' do
        it 'returns only port mapppings assigned to concrete virtual machine' do
          get api("/port_mappings?virtual_machine_id=#{vm1.id}", user)
          expect(pms_response.size).to eq 1
          expect(pms_response[0]).to port_mapping_eq pm1
        end
      end
    end

    context 'when authenticated as admin' do
      it 'return all users port mapping when all flag set to true' do
        get api("/port_mappings?all=true", admin)
        expect(pms_response.size).to eq 3
      end
    end
  end

  describe 'GET /port_mappings/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/port_mappings/#{pm1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns user port mapping' do
        get api("/port_mappings/#{pm1.id}", user)
        expect(pm_response).to port_mapping_eq pm1
      end

      it 'return 403 (Forbidden) when getting not owned port mapping' do
        get api("/port_mappings/#{other_user_pm.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns not owned user port mapping' do
        get api("/port_mappings/#{other_user_pm.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  def pms_response
    json_response['port_mappings']
  end

  def pm_response
    json_response['port_mapping']
  end
end