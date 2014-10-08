require 'rails_helper'

describe Atmosphere::Api::V1::ApplianceTypesController do
  include ApiHelpers

  describe 'GET /appliance_types' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_types')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        user = create(:user)
        get api('/appliance_types', user)
        expect(response.status).to eq 200
      end

      it 'returns appliance types (all and owned)' do
        user = create(:user)
        at1 = create(:filled_appliance_type, author: user)
        at2 = create(:appliance_type, visible_to: :all)
        dev_at = create(:appliance_type, visible_to: :developer)

        get api('/appliance_types', user)

        expect(ats_response).to be_an Array
        expect(ats_response.size).to eq 2
        expect(ats_response[0]).to appliance_type_eq at1
        expect(ats_response[1]).to appliance_type_eq at2
      end

      it 'does not returns not owned appliance types' do
        user = create(:user)
        at1 = create(:appliance_type, visible_to: :owner)
        at2 = create(:appliance_type, visible_to: :all)

        get api('/appliance_types', user)

        expect(ats_response.size).to eq 1
        expect(ats_response[0]).to appliance_type_eq at2
      end

      context 'pdp' do
        let(:pdp) { double('pdp') }
        let(:pdp_class) { double('pdp class', new: pdp) }

        before do
          allow(Air.config).to receive(:at_pdp_class).and_return(pdp_class)
        end

        it 'uses pdp to limit number of returned ATs' do
          user = create(:user)
          create(:appliance_type, visible_to: :all)
          at = create(:appliance_type, visible_to: :all)
          allow(pdp).to receive(:filter)
            .with(anything, nil).and_return([at])

          get api('/appliance_types', user)

          expect(ats_response.size).to eq 1
          expect(ats_response[0]).to appliance_type_eq at
        end

        it 'uses pdp to limit number of returned ATs in production mode' do
          user = create(:user)
          create(:appliance_type, visible_to: :all)
          at = create(:appliance_type, visible_to: :all)
          allow(pdp).to receive(:filter)
            .with(anything, 'production').and_return([at])

          get api('/appliance_types?mode=production', user)

          expect(ats_response.size).to eq 1
          expect(ats_response[0]).to appliance_type_eq at
        end
      end

      context 'search' do
        it 'returns only appliance types created by the user' do
          user = create(:user)
          user_at1 = create(:filled_appliance_type, author: user)
          user_at2 = create(:appliance_type, visible_to: :all, author: user)
          create(:appliance_type, visible_to: :all)

          get api("/appliance_types?author_id=#{user.id}", user)
          expect(ats_response.size).to eq 2

          expect(ats_response[0]).to appliance_type_eq user_at1
          expect(ats_response[1]).to appliance_type_eq user_at2
        end

        context 'using active flag' do
          it 'returns only active types' do
            user = create(:user)
            at1 = create(:filled_appliance_type, author: user)
            at2 = create(:appliance_type, visible_to: :all)
            at3 = create(:appliance_type, visible_to: :all)
            create(:virtual_machine_template, state: :active, appliance_type: at1)
            create(:virtual_machine_template, state: :saving, appliance_type: at2)

            get api("/appliance_types?active=true", user)

            expect(ats_response.size).to eq 1
            expect(ats_response[0]).to appliance_type_eq at1
          end

          it 'returns only inactive types' do
            user = create(:user)
            at1 = create(:appliance_type, visible_to: :all)
            at2 = create(:appliance_type, visible_to: :all)
            at3 = create(:appliance_type, visible_to: :all)
            create(:virtual_machine_template, state: :active, appliance_type: at1)
            create(:virtual_machine_template, state: :saving, appliance_type: at3)

            get api("/appliance_types?active=false", user)
            expect(ats_response.size).to eq 2
            expect(ats_response[0]).to appliance_type_eq at2
            expect(ats_response[1]).to appliance_type_eq at3
          end

          it 'don\'t duplicate ATs when VMT located on 2 compute sites' do
            user = create(:user)
            at1 = create(:filled_appliance_type, author: user)
            create(:virtual_machine_template, state: :active, appliance_type: at1)
            create(:virtual_machine_template, state: :active, appliance_type: at1)

            get api("/appliance_types?active=true", user)

            expect(ats_response.size).to eq 1
          end
        end
      end
    end

    context 'when authenticated as developer' do
      it 'returns appliance types (all and for developers)' do
        developer = create(:developer)
        public_at = create(:appliance_type, visible_to: :all)
        dev_at    = create(:appliance_type, visible_to: :developer)
        create(:appliance_type, visible_to: :owner)

        get api('/appliance_types', developer)

        expect(ats_response.size).to eq 2
        expect(ats_response[0]).to appliance_type_eq public_at
        expect(ats_response[1]).to appliance_type_eq dev_at
      end
    end

    context 'when authenticated as admin' do
      it 'returns all available appliance types (owned, not owned, all, for developers) when all flag is set to true' do
        admin     = create(:admin)
        owner_at  = create(:appliance_type, visible_to: :owner)
        public_at = create(:appliance_type, visible_to: :all)
        dev_at    = create(:appliance_type, visible_to: :developer)

        get api('/appliance_types?all=true', admin)

        expect(ats_response.size).to eq 3
        expect(ats_response[0]).to appliance_type_eq owner_at
        expect(ats_response[1]).to appliance_type_eq public_at
        expect(ats_response[2]).to appliance_type_eq dev_at
      end
    end
  end

  describe "GET /appliance_types/:id" do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        at = create(:appliance_type, visible_to: :all)

        get api("/appliance_types/#{at.id}")

        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        user = create(:user)
        at = create(:appliance_type, visible_to: :all)

        get api("/appliance_types/#{at.id}", user)

        expect(response.status).to eq 200
      end

      it 'returns appliance type' do
        user = create(:user)
        at = create(:appliance_type, visible_to: :all)

        get api("/appliance_types/#{at.id}", user)

        expect(at_response).to appliance_type_eq at
      end

      it 'returns 404 Not Found when appliance type is not found' do
        user = create(:user)

        get api("/appliance_types/non_existing", user)

        expect(response.status).to eq 404
      end

      it 'returns compute sites for appliance type' do
        user = create(:user)
        cs1  = create(:compute_site)
        cs2  = create(:compute_site)
        at   = create(:appliance_type, visible_to: :all)
        create(:virtual_machine_template, compute_site: cs1, appliance_type: at)
        create(:virtual_machine_template, compute_site: cs2, appliance_type: at)

        get api("/appliance_types/#{at.id}", user)

        expect(at_response["compute_site_ids"]).to include(cs1.id, cs2.id)

      end

      it 'does not return the same compute site twice for appliance type' do
        user = create(:user)
        cs1  = create(:compute_site)

        at  = create(:appliance_type, visible_to: :all)
        create(:virtual_machine_template, compute_site: cs1, appliance_type: at)
        create(:virtual_machine_template, compute_site: cs1, appliance_type: at)

        get api("/appliance_types/#{at.id}", user)
        expect(at_response["compute_site_ids"]).to eq [cs1.id]
      end
    end
  end

  describe 'active property' do
    it 'returns AT active flag false when no VMT assigned' do
      user = create(:user)
      at   = create(:appliance_type, visible_to: :all)

      get api("/appliance_types/#{at.id}", user)

      expect(at_response['active']).to eq false
    end

    it 'returns AT active flag false when no active VMT assigned' do
      user = create(:user)
      at   = create(:appliance_type, visible_to: :all)
      create(:virtual_machine_template, state: :saving, appliance_type: at)

      get api("/appliance_types/#{at.id}", user)

      expect(at_response['active']).to eq false
    end

    it 'returns AT active flag true when active VMT assigned' do
      user = create(:user)
      at   = create(:appliance_type, visible_to: :all)
      create(:virtual_machine_template, state: :active, appliance_type: at)

      get api("/appliance_types/#{at.id}", user)

      expect(at_response['active']).to be_truthy
    end
  end

  describe 'PUT /appliance_types/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        at = create(:appliance_type)

        put api("/appliance_types/#{at.id}")

        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        user = create(:user)
        at = create(:appliance_type, author: user)

        put api("/appliance_types/#{at.id}", user), update_msg

        expect(response.status).to eq 200
      end

      it 'updates appliance type' do
        user = create(:user)
        different_user = create(:user)
        at = create(:appliance_type, author: user)
        msg = update_msg(
            author_id: different_user.id
          )

        put api("/appliance_types/#{at.id}", user), msg
        at.reload

        expect(at).to at_be_updated_by msg[:appliance_type]
        expect(at_response).to appliance_type_eq at
      end

      it 'returns 422 when entity error' do
        user = create(:user)
        at = create(:appliance_type, author: user)
        msg = { appliance_type: { preference_cpu: -2 } }

        put api("/appliance_types/#{at.id}", user), msg

        expect(response.status).to eq 422
      end

      it 'returns 403 when user is not an appliance type owner' do
        user = create(:user)
        at = create(:appliance_type)

        put api("/appliance_types/#{at.id}", user), update_msg

        expect(response.status).to eq 403
      end

      it 'return 404 Not Found when appliance type is not found' do
        user = create(:user)

        put api("/appliance_types/non_existing", user), update_msg

        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'updates not owned appliance type' do
        admin = create(:admin)
        at = create(:appliance_type)

        put api("/appliance_types/#{at.id}", admin), update_msg

        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /appliance_types' do

    before do
      Fog.mock!
      allow(Atmosphere::Optimizer.instance).to receive(:run)
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliance_types/"), create_msg

        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user without developer role' do
      it 'returns 403 Forbidden error' do
        user = create(:user)

        post api("/appliance_types/", user), create_msg

        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as developer' do

      it 'returns 422 error if appliance id is not provided' do
        developer = create(:developer)

        post api("/appliance_types/", developer), create_msg
        expect(response.status).to eq 422
      end

      it 'returns 201 Created on success' do
        developer, appl = developer_with_appl
        msg = create_msg(appliance_id: appl.id)

        post api("/appliance_types/", developer), msg
        expect(response.status).to eq 201
      end

      it 'creates new appliance type' do
        developer, appl = developer_with_appl
        msg = create_msg(appliance_id: appl.id)

        expect {
          post api("/appliance_types/", developer), msg
        }.to change { Atmosphere::ApplianceType.count }.by(1)
      end

      it 'sets AT properties from appliance dev mode property set' do
        developer, appl = developer_with_appl
        msg = create_msg(appliance_id: appl.id)

        post api("/appliance_types/", developer), msg

        expect(at_response['name']).to eq msg[:appliance_type][:name]
        expect(at_response['description']).to be_nil
        expect(at_response['shared']).to be_falsy
        expect(at_response['scalable']).to be_falsy
        expect(at_response['visible_to']).to eq 'owner'
      end

      it 'creates new appliance type with owner set to other user' do
        developer, appl = developer_with_appl
        other_user = create(:user)
        msg = create_msg(
                  appliance_id: appl.id,
                  author_id: other_user.id
                )

        post api("/appliance_types/", developer), msg

        expect(at_response['author_id']).to eq other_user.id
      end

      it 'sets current user when no other given' do
        developer, appl = developer_with_appl
        msg = create_msg(appliance_id: appl.id)

        post api("/appliance_types/", developer), msg
        expect(at_response['author_id']).to eq developer.id
      end

      context 'when pmt, endpoint and pmt property exists' do
        it 'creates pmt copy from appliance pmt' do
          developer, appl = developer_with_appl
          create(:port_mapping_template,
              dev_mode_property_set: appl.dev_mode_property_set,
              appliance_type: nil
            )
          msg = create_msg(appliance_id: appl.id)

          expect {
            post api("/appliance_types/", developer), msg
          }.to change { Atmosphere::PortMappingTemplate.count }.by(1)
        end

        it 'creates pmt property copy from appliance pmt' do
          developer, appl = developer_with_appl
          pmt = create(:port_mapping_template,
                    dev_mode_property_set: appl.dev_mode_property_set,
                    appliance_type: nil
                  )
          create(:pmt_property, port_mapping_template: pmt)
          msg = create_msg(appliance_id: appl.id)

          expect {
            post api("/appliance_types/", developer), msg
          }.to change { Atmosphere::PortMappingProperty.count }.by(1)
        end

        it 'creates endpoint copy from appliance pmt' do
          developer, appl = developer_with_appl
          pmt = create(:port_mapping_template,
                    dev_mode_property_set: appl.dev_mode_property_set,
                    appliance_type: nil
                  )
          create(:endpoint, port_mapping_template: pmt)
          msg = create_msg(appliance_id: appl.id)

          expect {
            post api("/appliance_types/", developer), msg
          }.to change { Atmosphere::Endpoint.count }.by(1)
        end
      end

      context 'appliance id is provided in request' do
        it 'merges attributes from dev mode property set of given appliance with those provided in request parameters' do
          developer, appl = developer_with_appl
          name, description = "at name", "at description"
          dev_name_and_desc!(appl, name, description)
          msg = create_msg(appliance_id: appl.id)

          post api('/appliance_types/', developer), msg
          created_at = Atmosphere::ApplianceType.find(at_response['id'])

          expect(created_at.name).to eq msg[:appliance_type][:name]
          expect(created_at.description).to eq description
        end

        it 'returns error if appliance with given id does not exist' do
          developer = create(:developer)
          msg = create_msg(appliance_id: 1111111)

          post api('/appliance_types/', developer), msg

          expect(response.status).to eq 404
          expect(json_response)
            .to eq error_response('Record not found', 'general')
        end

        it 'returns error if appliance with given id does not belong to user' do
          _, appl = developer_with_appl
          other_developer = create(:developer)
          msg = create_msg(appliance_id: appl.id)

          post api('/appliance_types/', other_developer), msg

          expect(response.status).to eq 403
          expect(json_response)
            .to eq error_response('403 Forbidden', 'general')
        end

        it 'returns error if appliance is not on dev mode' do
          developer = create(:developer)
          wf_appl_set = create(:workflow_appliance_set)
          appl = create(:appliance, appliance_set: wf_appl_set)
          msg = create_msg(appliance_id: appl.id)

          post api('/appliance_types/', developer), msg

          expect(response.status).to eq 403
          expect(json_response)
            .to eq error_response('403 Forbidden', 'general')
        end

        it 'saves developer\'s virtual machine as template when creating new appliance type' do
          developer, appl = developer_with_appl
          msg = create_msg(appliance_id: appl.id)
          cloud_client = double('cloud client')
          allow(cloud_client).to receive(:save_template).and_return('99')
          allow(Fog::Compute).to receive(:new).and_return cloud_client
          vm = create(:virtual_machine)
          appl.virtual_machines << vm

          expect {
            post api('/appliance_types/', developer), msg
            vm.reload
          }.to change { Atmosphere::VirtualMachineTemplate.count }.by(1)

          expect(vm.saved_templates.size).to eq 1
          tmpl = vm.saved_templates.first
          expect(tmpl.state).to eq 'saving'
          expect(tmpl.appliance_type_id).to eq at_response['id']
        end

        it 'returns 409 Conflict when appliance is already used to save AT' do
          developer, appl = developer_with_appl
          create(:virtual_machine, appliances: [appl], state: :saving)
          msg = create_msg(appliance_id: appl.id)

          post api("/appliance_types/", developer), msg

          expect(response.status).to eq 409
        end
      end
    end

    context 'when authenticated as admin' do
      it 'allows to create new appliance even if given appliance is not owned by user' do
        admin = create(:admin)
        _, appl = developer_with_appl
        msg = create_msg(appliance_id: appl.id)

        post api('/appliance_types/', admin), msg

        expect(response.status).to eq 201
      end

      it 'allows to create new appliance even if appliance id is not provided' do
        admin = create(:admin)

        post api('/appliance_types/', admin), create_msg

        expect(response.status).to eq 201
      end

    end
  end

  describe 'DELETE /appliance_types/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        at = create(:appliance_type)

        delete api("/appliance_types/#{at.id}")

        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        user, at = user_with_at

        delete api("/appliance_types/#{at.id}", user)

        expect(response.status).to eq 200
      end

      it 'deletes appliance type' do
        user, at = user_with_at

        expect {
          delete api("/appliance_types/#{at.id}", user)
        }.to change { Atmosphere::ApplianceType.count }.by(-1)
      end

      it 'returns 403 when user is not and appliance type owner' do
        not_owner = create(:user)
        at   = create(:appliance_type)

        expect {
          delete api("/appliance_types/#{at.id}", not_owner)
          expect(response.status).to eq 403
        }.to change { Atmosphere::ApplianceType.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'deletes appliance type even if no owner' do
        admin = create(:admin)
        at = create(:appliance_type)

        expect {
          delete api("/appliance_types/#{at.id}", admin)
        }.to change { Atmosphere::ApplianceType.count }.by(-1)
      end
    end
  end

  describe 'GET /appliance_types/:id/endpoints/:service_name/:invocation_path' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error for not visible for all appliance types' do
        at = create(:appliance_type)
        _, invocation_path =
          endpoint_with_invocation_path(at)

        get api(invocation_path)

        expect(response.status).to eq 401
      end

      it 'returns 200 Success' do
        at = create(:appliance_type, visible_to: :all)
        _, invocation_path =
          endpoint_with_invocation_path(at)

        get api(invocation_path)

        expect(response.status).to eq 200
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        user = create(:user)
        at = create(:appliance_type, author: user)
        _, invocation_path = endpoint_with_invocation_path(at)

        get api(invocation_path, user)

        expect(response.status).to eq 200
      end

      it 'returns endpoint descriptor' do
        user = create(:user)
        at = create(:appliance_type, visible_to: :all)
        endpoint, invocation_path = endpoint_with_invocation_path(at)

        get api(invocation_path, user)

        expect(response.body).to eq endpoint.descriptor
      end

      it 'return 404 Not Found when endpoint does not exist' do
        user = create(:user)
        at = create(:appliance_type, author: user)
        endpoint, invocation_path = endpoint_with_invocation_path(at)

        get api("#{invocation_path}/not/existing", user)

        expect(response.status).to eq 404
      end

      it 'returns 403 Forbidden when user has not right to see appliance type' do
        not_owner = create(:user)
        at = create(:appliance_type)
        endpoint, invocation_path = endpoint_with_invocation_path(at)

        get api(invocation_path, not_owner)

        expect(response.status).to eq 403
      end
    end
  end

  def ats_response
    json_response['appliance_types']
  end

  def at_response
    json_response['appliance_type']
  end

  def update_msg(overrides = {})
    update_hsh = {
      appliance_type: {
        name: 'new name',
        description: 'new description',
        shared: true,
        scalable: true,
        visible_to: :all,
        preference_cpu: 10.0,
        preference_memory: 1024,
        preference_disk: 10240
      }
    }
    override(update_hsh, overrides)

    update_hsh
  end

  def create_msg(overrides = {})
    create_hsh = {appliance_type: { name: 'New AT name' } }

    override(create_hsh, overrides)

    create_hsh
  end

  def override(hsh, overrides)
    overrides.each {|k, v| hsh[:appliance_type][k] = v}
    hsh
  end

  def developer_with_appl
    developer  = create(:developer)
    appl_set   = create(:dev_appliance_set, user: developer)
    appl       = create(:appl_dev_mode, appliance_set: appl_set)

    [developer, appl]
  end

  def dev_name_and_desc!(appl, name, description)
    appl.dev_mode_property_set.name = name
    appl.dev_mode_property_set.description = description
    appl.save
  end

  def user_with_at
    user = create(:user)
    at   = create(:appliance_type, author: user)

    [user, at]
  end

  def endpoint_with_invocation_path(at)
    pmt = create(:port_mapping_template, appliance_type: at)
    endpoint = create(:endpoint,
        invocation_path: 'invocation/path',
        descriptor: 'payload',
        port_mapping_template: pmt
      )

    invocation_path = [
        '/appliance_types',
        at.id,
        'endpoints',
        pmt.service_name,
        endpoint.invocation_path
      ].join('/')

    [endpoint, invocation_path]
  end
end