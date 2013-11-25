require 'spec_helper'

describe Api::V1::ApplianceTypesController do
  include ApiHelpers

  let(:user)           { create(:user) }
  let(:different_user) { create(:user) }
  let(:developer)      { create(:developer) }
  let(:admin)          { create(:admin) }

  let(:security_proxy) { create(:security_proxy) }

  let!(:at1) { create(:filled_appliance_type, author: user, security_proxy: security_proxy) }
  let!(:at2) { create(:appliance_type, visible_for: :all) }
  let!(:dev_at) { create(:appliance_type, visible_for: :developer) }

  describe 'GET /appliance_types' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_types')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/appliance_types', user)
        expect(response.status).to eq 200
      end

      it 'returns appliance types (all and owned)' do
        get api('/appliance_types', user)
        expect(ats_response).to be_an Array
        expect(ats_response.size).to eq 2

        expect(ats_response[0]).to appliance_type_eq at1
        expect(ats_response[1]).to appliance_type_eq at2
      end

      it 'does not returns not owned appliance types' do
        get api('/appliance_types', different_user)
        expect(ats_response.size).to eq 1
        expect(ats_response[0]).to appliance_type_eq at2
      end

      context 'search' do
        let!(:second_user_at) { create(:appliance_type, visible_for: :all, author: user) }

        it 'returns only appliance types created by the user' do
          get api("/appliance_types?user_id=#{user.id}", user)
          expect(ats_response.size).to eq 2

          expect(ats_response[0]).to appliance_type_eq at1
          expect(ats_response[1]).to appliance_type_eq second_user_at
        end
      end

      pending 'pagination'
    end

    context 'when authenticated as developer' do
      it 'returns appliance types (all and for developers)' do
        get api('/appliance_types', developer)
        expect(ats_response.size).to eq 2
        expect(ats_response[0]).to appliance_type_eq at2
        expect(ats_response[1]).to appliance_type_eq dev_at
      end
    end

    context 'when authenticated as admin' do
      it 'returns all available appliance types (owned, not owned, all, for developers) when all flag is set to true' do
        get api('/appliance_types?all=true', admin)
        expect(ats_response.size).to eq 3
        expect(ats_response[0]).to appliance_type_eq at1
        expect(ats_response[1]).to appliance_type_eq at2
        expect(ats_response[2]).to appliance_type_eq dev_at
      end
    end
  end

  describe "GET /appliance_types/:id" do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/appliance_types/#{at1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance types' do
        get api("/appliance_types/#{at1.id}", user)
        expect(at_response).to appliance_type_eq at1
      end

      it 'returns 404 Not Found when appliance type is not found' do
        get api("/appliance_types/non_existing", user)
        expect(response.status).to eq 404
      end
    end
  end

  describe 'active property' do
    context 'when not virtual machine template assigned into appliance type' do
      it 'returns AT with active flag set to false' do
        get api("/appliance_types/#{at1.id}", user)
        expect(at_response['active']).to eq false
      end
    end

    context 'when virtual machine template with state other than active assigned into appliance type' do
      let!(:vmt) { create(:virtual_machine_template, state: :saving, appliance_type: at1) }

      it 'returns AT with active flag set to false' do
        get api("/appliance_types/#{at1.id}", user)
        expect(at_response['active']).to eq false
      end
    end

    context 'when virtual machine template with active state assigned into appliance type' do
      let!(:vmt) { create(:virtual_machine_template, state: :active, appliance_type: at1) }

      it 'returns AT with active flag set to false' do
        get api("/appliance_types/#{at1.id}", user)
        expect(at_response['active']).to be_true
      end
    end
  end

  describe 'PUT /appliance_types/:id' do
    let(:different_security_proxy) { create(:security_proxy, name: 'different/one') }

    let(:update_json) do {appliance_type: {
        name: 'new name',
        description: 'new description',
        shared: true,
        scalable: true,
        visible_for: :all,
        preference_cpu: 10.0,
        preference_memory: 1024,
        preference_disk: 10240,
        security_proxy_id: different_security_proxy.id,
        author_id: different_user.id
    }} end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        put api("/appliance_types/#{at1.id}", user), update_json
        expect(response.status).to eq 200
      end

      it 'updates appliance type' do
        put api("/appliance_types/#{at1.id}", user), update_json
        updated_at = ApplianceType.find(at1.id)

        expect(updated_at).to at_be_updated_by update_json[:appliance_type]
        expect(at_response).to appliance_type_eq updated_at
      end

      it 'admin updates appliance types event when no appliance type owner' do
        put api("/appliance_types/#{at1.id}", admin), update_json
        expect(response.status).to eq 200
      end

      it 'returns 422 when entity error' do
        put api("/appliance_types/#{at1.id}", user), { appliance_type: {preference_cpu: -2 }}
        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not an appliance type owner' do
        put api("/appliance_types/#{at1.id}", different_user), update_json
        expect(response.status).to eq 403
      end

      it 'return 404 Not Found when appliance type is not found' do
        put api("/appliance_types/non_existing", user), update_json
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /appliance_types' do

    before do
      Fog.mock!
      Optimizer.instance.stub(:run)
    end

    DEV_PROPS_NAME = 'Name from dev props'
    DEV_PROPS_DESC = 'Description from dev props'

    let(:appl_set) { create(:dev_appliance_set, user: developer) }
    let(:appl) { create(:appl_dev_mode, appliance_set: appl_set) }
    let(:new_at_name) { 'the newest appliance type ever' }
    let(:at_req_body) { {appliance_type: {name: new_at_name}} }
    let!(:req_with_appl_id_body) { {appliance_type: {name: new_at_name, appliance_id: appl.id}} }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliance_types/"), at_req_body
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user without developer role' do
      it 'returns 403 Forbidden error' do
        post api("/appliance_types/", user), at_req_body
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as developer' do

      it 'returns 422 error if appliance id is not provided' do
        post api("/appliance_types/", developer), at_req_body
        expect(response.status).to eq 422
      end

      it 'returns 201 Created' do
        post api("/appliance_types/", developer), req_with_appl_id_body
        expect(response.status).to eq 201
      end

      it 'creates new appliance type' do
        expect {
          post api("/appliance_types/", developer), req_with_appl_id_body
          expect(at_response['name']).to eq new_at_name
          expect(at_response['description']).to be_nil
          expect(at_response['shared']).to be_false
          expect(at_response['scalable']).to be_false
          expect(at_response['visible_for']).to eq 'owner'
        }.to change { ApplianceType.count }.by(1)

      end

      context 'appliance id is provided in request' do

        it 'merges attributes from dev mode property set of given appliance with those provided in request parameters' do
          appl.dev_mode_property_set.name = DEV_PROPS_NAME
          appl.dev_mode_property_set.description = DEV_PROPS_DESC
          appl.save
          post api('/appliance_types/', developer), req_with_appl_id_body
          created_at = ApplianceType.find(at_response['id'])
          expect(created_at.name).to eq new_at_name
          expect(created_at.description).to eq DEV_PROPS_DESC
        end

        it 'returns error if appliance with given id does not exist' do
          req = {appliance_type: {name: new_at_name, appliance_id: 1111111}}
          post api('/appliance_types/', developer), req
          expect(response.status).to eq 404
          expect(response.body).to eq '{"message":"Record not found"}'
        end

        it 'returns error if appliance with given id does not belong to user' do
          user = create(:developer)
          post api('/appliance_types/', user), req_with_appl_id_body
          expect(response.status).to eq 403
          expect(response.body).to eq '{"message":"403 Forbidden"}'
        end

        it 'returns error if appliance is not on dev mode' do
          wf_appl_set = create(:workflow_appliance_set)
          appl = create(:appliance, appliance_set: wf_appl_set)
          post api('/appliance_types/', developer), {appliance_type: {name: new_at_name, appliance_id: appl.id}}
          expect(response.status).to eq 403
          expect(response.body).to eq '{"message":"403 Forbidden"}'
        end

        it 'saves developer\'s virtual machine as template when creating new appliance type' do
          cloud_client = double('cloud client')
          expect(cloud_client).to receive(:save_template).and_return(99)
          Fog::Compute.stub(:new).and_return cloud_client
          vm = create(:virtual_machine)
          appl.virtual_machines << vm
          expect(vm.saved_templates.size).to eq 0
          expect { post api('/appliance_types/', developer), req_with_appl_id_body }.to change { VirtualMachineTemplate.count }.by(1)
          vm.reload
          expect(vm.saved_templates.size).to eq 1
          tmpl = vm.saved_templates.first
          expect(tmpl.state).to eq 'saving'
          expect(tmpl.appliance_type_id).to eq at_response['id']
        end
      end

    end

    context 'when authenticated as admin' do

      it 'allows to create new appliance even if given appliance is not owned by user' do
        post api('/appliance_types/', admin), req_with_appl_id_body
        expect(response.status).to eq 201
      end

      it 'allows to create new appliance even if appliance id is not provided' do
        post api('/appliance_types/', admin), at_req_body
        expect(response.status).to eq 201
      end

    end

  end

  describe 'DELETE /appliance_types/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliance_types/#{at1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        delete api("/appliance_types/#{at1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes appliance type' do
        expect {
          delete api("/appliance_types/#{at1.id}", user)
        }.to change { ApplianceType.count }.by(-1)
      end

      it 'admin deletes appliance type even if no owner' do
        expect {
          delete api("/appliance_types/#{at1.id}", admin)
        }.to change { ApplianceType.count }.by(-1)
      end

      it 'returns 403 when user is not and appliance type owner' do
        expect {
          delete api("/appliance_types/#{at1.id}", different_user)
          expect(response.status).to eq 403
        }.to change { ApplianceType.count }.by(0)
      end
    end
  end

  def ats_response
    json_response['appliance_types']
  end

  def at_response
    json_response['appliance_type']
  end
end