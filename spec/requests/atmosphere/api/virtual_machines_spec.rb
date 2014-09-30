require 'rails_helper'

describe Atmosphere::Api::V1::VirtualMachinesController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:set)   { create(:appliance_set, user: user) }
  let(:appl1) { create(:appliance, appliance_set: set) }
  let(:appl2) { create(:appliance, appliance_set: set) }

  let!(:vm1) { create(:virtual_machine, appliances: [ appl1 ]) }
  let!(:vm2) { create(:virtual_machine, appliances: [ appl1, appl2 ]) }
  let!(:other_user_vm) { create(:virtual_machine) }

  describe 'GET /virtual_machines' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/virtual_machines')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/virtual_machines', user)
        expect(response.status).to eq 200
      end

      it 'returns only user virtual machines' do
        get api('/virtual_machines', user)
        expect(vms_response).to be_an Array
        expect(vms_response.size).to eq 2
        expect(vms_response[0]).to vm_eq vm1
        expect(vms_response[1]).to vm_eq vm2
      end

      context 'search' do
        it 'returns vms specific for given appliance' do
          get api("/virtual_machines?appliance_id=#{appl2.id}", user)
          expect(vms_response.size).to eq 1
          expect(vms_response[0]).to vm_eq vm2
        end

        it 'returns only vms started on selected compute site' do
          get api("/virtual_machines?compute_site_id=#{vm1.compute_site.id}", user)
          expect(vms_response.size).to eq 1
          expect(vms_response[0]).to vm_eq vm1
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns all virtual machines when all flag is set to true' do
        get api('/virtual_machines?all=true', admin)
        expect(vms_response.size).to eq 3
      end
    end
  end

  describe 'GET /virtual_machines/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/virtual_machines/#{vm1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/virtual_machines/#{vm1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns owned vm details' do
        get api("/virtual_machines/#{vm1.id}", user)
        expect(vm_response).to vm_eq vm1
      end

      it 'returns 403 Forbiden for not owned vm' do
        get api("/virtual_machines/#{other_user_vm.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns details of not owned vm' do
        get api("/virtual_machines/#{other_user_vm.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  def vms_response
    json_response['virtual_machines']
  end

  def vm_response
    json_response['virtual_machine']
  end
end