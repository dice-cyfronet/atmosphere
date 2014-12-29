require 'rails_helper'

describe Atmosphere::Api::V1::AppliancesController do
  include ApiHelpers

  let(:optimizer) {double}

  let(:user)  { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:developer) { create(:developer) }

  let(:user_as) { create(:appliance_set, user: user) }
  let(:other_user_as) { create(:appliance_set, user: other_user) }

  let!(:user_appliance1) { create(:appliance, appliance_set: user_as, state: :unsatisfied, state_explanation: "flavour not found") }
  let!(:user_appliance2) { create(:appliance, appliance_set: user_as, amount_billed: 100) }
  let!(:other_user_appliance) { create(:appliance, appliance_set: other_user_as) }

  describe 'GET /appliances' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliances")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliances", user)
        expect(response.status).to eq 200
      end

      it 'returns only user appliances' do
        get api("/appliances", user)
        expect(appliances_response).to be_an Array
        expect(appliances_response.size).to eq 2
        expect(appliances_response[0]).to appliance_eq user_appliance1
        expect(appliances_response[1]).to appliance_eq user_appliance2
      end

      context 'search' do
        it 'returns only appliances belonging to select appliance set' do
          second_user_as = create(:appliance_set, user: user)
          second_as_appliance = create(:appliance, appliance_set: second_user_as)

          get api("/appliances?appliance_set_id=#{second_user_as.id}", user)
          expect(appliances_response.size).to eq 1
          expect(appliances_response[0]).to appliance_eq second_as_appliance
        end

        it 'returns appliances connected with concrete VM' do
          cs = create(:compute_site)
          vm = create(:virtual_machine, compute_site: cs)
          appliance = create(:appliance,
            virtual_machines: [vm], appliance_set: user_as)
          other_appliance = create(:appliance, appliance_set: user_as)

          get api("/appliances?virtual_machine_ids=#{vm.id}", user)

          expect(appliances_response.size).to eq 1
          expect(appliances_response[0]).to appliance_eq appliance
        end
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:admin) }

      it 'returns only owned appliances when no all flag' do
        get api("/appliances", admin)
        expect(appliances_response).to be_an Array
        expect(appliances_response.size).to eq 0
      end

      it 'returns all appliances when all flag set to true' do
        get api("/appliances?all=true", admin)
        expect(appliances_response.size).to eq 3
      end
    end
  end

  describe 'GET /appliances/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliances/#{user_appliance1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliances/#{user_appliance1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns appliance details' do
        get api("/appliances/#{user_appliance1.id}", user)
        expect(appliance_response).to appliance_eq user_appliance1
      end

      it 'returns 403 Forbidden when getting other user appliance details' do
        get api("/appliances/#{other_user_appliance.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns appliance details of other user appliance' do
        get api("/appliances/#{other_user_appliance.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  describe 'GET /appliances/:id/endpoints' do


    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliances/#{user_appliance1.id}/endpoints")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:at) { create(:appliance_type) }
      let(:pmt1) { create(:port_mapping_template, appliance_type: at, transport_protocol: :tcp, application_protocol: :http_https) }
      let(:pmt2) { create(:port_mapping_template, appliance_type: at, transport_protocol: :tcp, application_protocol: :http) }

      let!(:pmt1_endpoint)  { create(:endpoint, port_mapping_template: pmt1, endpoint_type: :webapp, invocation_path: 'e1') }
      let!(:pmt2_endpoint1) { create(:endpoint, port_mapping_template: pmt2, endpoint_type: :ws, invocation_path: 'e2') }
      let!(:pmt2_endpoint2) { create(:endpoint, port_mapping_template: pmt2, endpoint_type: :rest, invocation_path: 'e3') }


      let(:appl) { create(:appliance, appliance_type: at, appliance_set: user_as) }
      let!(:http_mapping1) { create(:http_mapping, appliance: appl, application_protocol: :http, port_mapping_template: pmt1, url: 'url1') }
      let!(:http_mapping2) { create(:http_mapping, appliance: appl, application_protocol: :https, port_mapping_template: pmt1, url: 'url2') }
      let!(:http_mapping3) { create(:http_mapping, appliance: appl, application_protocol: :http, port_mapping_template: pmt2, url: 'url3') }

      it 'returns 200 on success' do
        get api("/appliances/#{appl.id}/endpoints", user)
        expect(response.status).to eq 200
      end

      it 'returns endpoints details' do
        get api("/appliances/#{appl.id}/endpoints", user)
        expect(endpoints_response).to be_an Array
        expect(endpoints_response.size).to eq 3
        sorted_endpoints = endpoints_response.sort { |x,y| x['id'] <=> y['id'] }

        expect(sorted_endpoints[0]).to appl_endpoint_eq pmt1_endpoint, ['url1/e1', 'url2/e1']
        expect(sorted_endpoints[1]).to appl_endpoint_eq pmt2_endpoint1, ['url3/e2']
        expect(sorted_endpoints[2]).to appl_endpoint_eq pmt2_endpoint2, ['url3/e3']
      end
    end
  end

  describe 'POST /appliances' do
    let!(:portal_set) { create(:appliance_set, user: user, appliance_set_type: :portal)}
    let!(:development_set) { create(:appliance_set, user: developer, appliance_set_type: :development)}

    let!(:fund) { create(:fund) }

    let!(:public_at) { create(:appliance_type, visible_to: :all) }

    let(:static_config) { create(:static_config_template, appliance_type: public_at) }
    let(:static_request_body) { start_request(static_config, portal_set) }

    let(:development_set) { create(:appliance_set, user: developer, appliance_set_type: :development)}


    let(:static_dev_request_body) do
      {
        appliance: {
          configuration_template_id: static_config.id,
          appliance_set_id: development_set.id,
          fund_id: fund.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("appliances"), static_request_body
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      before do
        allow(Atmosphere::Optimizer)
          .to receive(:instance).and_return(optimizer)
        expect(optimizer).to receive(:run).once
      end

      it 'returns 201 Created on success' do
        post api("/appliances", user), static_request_body
        expect(response.status).to eq 201
      end

      context 'with static config' do
        it 'creates config instance' do
          expect {
            post api("/appliances", user), static_request_body
          }.to change { Atmosphere::ApplianceConfigurationInstance.count}.by(1)
        end

        it 'creates new appliance' do
          expect {
            post api("/appliances", user), static_request_body
          }.to change { Atmosphere::Appliance.count}.by(1)
        end

        it 'copies config payload from template' do
          post api("/appliances", user), static_request_body
          config_instance = Atmosphere::ApplianceConfigurationInstance.find(appliance_response['appliance_configuration_instance_id'])
          expect(config_instance.payload).to eq config_instance.appliance_configuration_template.payload
        end

        it 'sets appliance name and description' do
          post api("/appliances", user), static_request_body
          created_appliance = Atmosphere::Appliance.find(appliance_response['id'])

          expect(created_appliance.name)
            .to eq static_request_body[:appliance][:name]
          expect(created_appliance.description)
            .to eq static_request_body[:appliance][:description]
        end

        it 'copies name and descriptions from AT when not set' do
          request_body = generic_start_request(static_config, portal_set)

          post api("/appliances", user), request_body
          created_appliance = Atmosphere::Appliance.find(appliance_response['id'])

          expect(created_appliance.name)
            .to eq public_at.name
          expect(created_appliance.description)
            .to eq public_at.description
        end

        context 'and config instance already exists' do
          before do
            create(:appliance_configuration_instance, appliance_configuration_template: static_config, payload: static_config.payload)
          end

          it 'reuses configuratoin instance' do
            expect {
              post api("/appliances", user), static_request_body
            }.to change { Atmosphere::ApplianceConfigurationInstance.count}.by(0)
          end
        end
      end

      context 'with dynamic configuration' do
        let(:dynamic_config) { create(:appliance_configuration_template, appliance_type: public_at, payload: 'dynamic config #{param1} #{param2} #{param3}') }
        let(:dynamic_request_body) do
          {
            appliance: {
              configuration_template_id: dynamic_config.id,
              appliance_set_id: portal_set.id,
              params: {
                param1: 'a',
                param2: 'b',
                param3: 'c'
              }
            }
          }
        end

        it 'creates config instance with all required parameters' do
          post api("/appliances", user), dynamic_request_body
          expect(response.status).to eq 201
        end

        it 'creates dynamic configuration instance payload' do
          post api("/appliances", user), dynamic_request_body
          config_instance = Atmosphere::ApplianceConfigurationInstance.find(appliance_response['appliance_configuration_instance_id'])
          expect(config_instance.payload).to eq 'dynamic config a b c'
        end
      end

      context 'with appliance type already added to appliance set' do
        let(:config_instance) { create(:appliance_configuration_instance, payload: static_config.payload, appliance_configuration_template: static_config) }
        let(:second_static_config) { create(:static_config_template) }

        context 'when production appliance set' do
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: portal_set, appliance_type: static_config.appliance_type) }

          it 'returns 201 Created' do
            expect(optimizer).to receive(:run).once
            post api("/appliances", user), static_request_body
            expect(response.status).to eq 201
          end

          it 'does not create new configuration instance' do
            expect(optimizer).to receive(:run).once
            expect {
              post api("/appliances", user), static_request_body
            }.to change { Atmosphere::ApplianceConfigurationInstance.count}.by(0)
          end

          it 'creates new appliance' do
            expect(optimizer).to receive(:run).once
            expect {
              post api("/appliances", user), static_request_body
            }.to change { Atmosphere::Appliance.count}.by(1)
          end

          it 'creates new appliance when configuration payload the same but different appliance types' do
            post api("/appliances", user), {appliance: { configuration_template_id: second_static_config.id } }

          end

          context 'create new appl of the same AT with different configuration template' do

            before do
              # this is tricky, we expect optimizer to be run once in context 'with appliance type already added to appliance set'
              # and the second time in context 'create new appl of the same AT with different configuration template'
              expect(optimizer).to receive(:run).once
            end

            let(:another_conf_tmpl_for_the_same_at) { create(:static_config_template, appliance_type: public_at) }
            let(:req_for_second_appl_for_the_same_at) { start_request(another_conf_tmpl_for_the_same_at, portal_set) }

            it 'returns 201' do
              post api("/appliances", user), req_for_second_appl_for_the_same_at
              expect(response.status).to eq 201
            end

            it 'creates new appliance of the sam type when configuration template is different' do
              expect {
                post api("/appliances", user), req_for_second_appl_for_the_same_at
              }.to change { Atmosphere::Appliance.count}.by(1)
            end

          end
        end

        context 'when development appliance set' do
          let!(:existing_appliance) { create(:appliance, appliance_configuration_instance: config_instance, appliance_set: development_set) }

          it 'creates second appliance with the same configuration instance' do
            expect(optimizer).to receive(:run).once
            post api("/appliances", developer), static_dev_request_body
            expect(response.status).to eq 201
          end
        end
      end
    end

    context 'with private appliance type (visible_to: owner)' do
      let(:private_at) { create(:appliance_type, author: user, visible_to: :owner) }
      let(:private_at_config) { create(:static_config_template, appliance_type: private_at) }

      it 'allows to start appliance type by its author' do
        post api("/appliances", user), start_request(private_at_config, portal_set)
        expect(response.status).to eq 201
      end

      it 'does not allow to start appliance by other user' do
        post api("/appliances", other_user), start_request(private_at_config, other_user_as)
        expect(response.status).to eq 403
      end
    end

    context 'with development appliance type (visible_to: developer)' do
      let(:development_at) { create(:appliance_type, visible_to: :developer) }
      let(:development_at_config) { create(:static_config_template, appliance_type: development_at) }

      context 'when development mode' do
        it 'allows to start' do
          post api("/appliances", developer), start_request(development_at_config, development_set)
          expect(response.status).to eq 201
        end

        it 'allows overwrite preferences' do
          request = start_request(development_at_config, development_set)
          request[:appliance][:dev_mode_property_set] = {preference_memory: 123, preference_cpu: 2, preference_disk: 321}

          post api("/appliances", developer), request
          appl = Atmosphere::Appliance.find(appliance_response['id'])
          set = appl.dev_mode_property_set

          expect(set.preference_memory).to eq 123
          expect(set.preference_cpu).to eq 2
          expect(set.preference_disk).to eq 321
        end
      end

      it 'does not allow to start in production mode' do
        post api("/appliances", user), start_request(development_at_config, portal_set)
        expect(response.status).to eq 403
      end
    end

    context 'with_selected_compute_sites' do

      let!(:compute_site_1) {create(:compute_site)}
      let!(:compute_site_2) {create(:compute_site)}

      let!(:static_dev_request_body_with_one_cs) do
        {
            appliance: {
                configuration_template_id: static_config.id,
                appliance_set_id: development_set.id,
                fund_id: fund.id,
                compute_site_ids: [compute_site_1.id]
            }
        }
      end

      let!(:static_dev_request_body_with_two_cs) do
        {
            appliance: {
                configuration_template_id: static_config.id,
                appliance_set_id: development_set.id,
                fund_id: fund.id,
                compute_site_ids: [compute_site_1.id, compute_site_2.id]
            }
        }
      end

      before do
        allow(Atmosphere::Optimizer)
          .to receive(:instance).and_return(optimizer)
        expect(optimizer).to receive(:run).once
      end

      it 'creates new appliance with default cs binding' do
        expect {
          post api("/appliances", user), static_request_body
        }.to change { Atmosphere::ApplianceComputeSite.count}.by(2)
      end

      it 'creates new appliance bound to one cs' do
        post api("/appliances", developer), static_dev_request_body_with_one_cs
        a = Atmosphere::Appliance.find(appliance_response['id'])
        expect(a.compute_sites.count).to eq 1
      end

      it 'creates new appliance bound to two cs' do
        post api("/appliances", developer), static_dev_request_body_with_two_cs
        a = Atmosphere::Appliance.find(appliance_response['id'])
        expect(a.compute_sites.count).to eq 2
      end
    end


    context 'user keys' do
      context 'when in production mode' do
        let(:user_key) { create(:user_key, user: user) }

        it 'skips user key for started appliance' do
          post api("/appliances", user), user_key_request(static_request_body, user_key)

          created_appliance = Atmosphere::Appliance.find(appliance_response['id'])
          expect(created_appliance.user_key).to be_nil
        end
      end

      context 'when in development mode' do
        let(:developer_key) { create(:user_key, user: developer) }

        it 'injects user key for started appliance' do
          post api("/appliances", developer), user_key_request(static_dev_request_body, developer_key)

          created_appliance = Atmosphere::Appliance.find(appliance_response['id'])
          expect(created_appliance.user_key).to eq developer_key
        end
      end
    end
  end

  describe 'PUT /appliances/:id' do
    let(:update_request) do
      {
        appliance: {
          name: 'updated name',
          description: 'updated description'
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliances/#{user_appliance1.id}"), update_request
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Created on success' do
        put api("/appliances/#{user_appliance1.id}", user), update_request
        expect(response.status).to eq 200
      end

      it 'updates appliance name' do
        put api("/appliances/#{user_appliance1.id}", user), update_request
        user_appliance1.reload
        expect(user_appliance1.name).to eq update_request[:appliance][:name]
        expect(user_appliance1.description).to eq update_request[:appliance][:description]
      end

      it 'returns information about updated appliance' do
        put api("/appliances/#{user_appliance1.id}", user), update_request
        user_appliance1.reload
        expect(appliance_response).to appliance_eq user_appliance1
      end
    end
  end

  context 'DELETE /appliances/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliances/#{user_appliance1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Created on success' do
        delete api("/appliances/#{user_appliance1.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes user appliance' do
        expect {
          delete api("/appliances/#{user_appliance1.id}", user)
        }.to change { Atmosphere::Appliance.count }.by(-1)
      end

      it 'returns 403 Forbidden when trying to remove other user appliance' do
        delete api("/appliances/#{other_user_appliance.id}", user)
        expect(response.status).to eq 403
      end

      it 'does not remove other user appliance' do
        expect {
          delete api("/appliances/#{other_user_appliance.id}", user)
        }.to change { Atmosphere::Appliance.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'removes other user appliance' do
        expect {
          delete api("/appliances/#{other_user_appliance.id}", admin)
          expect(response.status).to eq 200
        }.to change { Atmosphere::Appliance.count }.by(-1)
      end
    end
  end

  context 'POST /appliances/:id/action not_found' do
    it 'returns 400 when action not found' do
      appliance = appliance_for(user, mode: :development)
      unknown_action_body = { not_found: nil }

      post api("/appliances/#{user_appliance1.id}/action", user), unknown_action_body

      expect(response.status).to eq 400
    end
  end

  context 'POST /appliances/:id/action reboot' do
    let(:reboot_action_body) { { reboot: nil } }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/appliances/#{user_appliance1.id}/action"), reboot_action_body
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'reboots owned appliance started in dev mode' do
        appliance = appliance_for(user, mode: :development)
        vm = create(:virtual_machine, appliances: [appliance])

        expect_any_instance_of(Atmosphere::VirtualMachine).to receive(:reboot)

        post api("/appliances/#{appliance.id}/action", user), reboot_action_body

        expect(response.status).to eq 200
      end

      it 'does not allow to reboot appliance started in production mode' do
        appliance = appliance_for(user, mode: :workflow)

        post api("/appliances/#{appliance.id}/action", user), reboot_action_body

        expect(response.status).to eq 403
      end

      it 'does not allow to reboot not owned appliance' do
        appliance = appliance_for(other_user, mode: :development)

        post api("/appliances/#{appliance.id}/action", user), reboot_action_body

        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'reboots not owned appliance' do
        appliance = appliance_for(user, mode: :development)

        post api("/appliances/#{appliance.id}/action", admin), reboot_action_body

        expect(response.status).to eq 200
      end

      it 'reboots appliance started in production mode' do
        appliance = appliance_for(user, mode: :workflow)

        post api("/appliances/#{appliance.id}/action", admin), reboot_action_body

        expect(response.status).to eq 200
      end
    end
  end

  context 'POST /appliances/:id/action scale' do

    context 'when authenticated' do

      let(:scale_up_action_body) { { scale: 1 } }
      let(:scale_down_action_body) { { scale: -1 } }

      let(:optimizer) { double('optimizer') }

      it 'scales up' do
        appliance = appliance_for(user, mode: :development)
        expect(Atmosphere::Optimizer).to receive(:instance) { optimizer }
        expect(optimizer).to receive(:run).with(hash_including(scaling: {appliance: appliance, quantity: 1}))
        post api("/appliances/#{appliance.id}/action", user), scale_up_action_body
        expect(response.status).to eq 200
      end

      it 'scales down' do
        appliance = appliance_for(user, mode: :development)
        vm = create(:virtual_machine, appliances: [appliance])
        expect(Atmosphere::Optimizer).to receive(:instance) { optimizer }
        expect(optimizer).to receive(:run).with(hash_including(scaling: {appliance: appliance, quantity: -1}))
        post api("/appliances/#{appliance.id}/action", user), scale_down_action_body
        expect(response.status).to eq 200
      end

    end
  end

  def appliance_for(user, options = {})
    as_mode = options[:mode] || :workflow
    as = create(:appliance_set,
      appliance_set_type: as_mode, user: user)
    create(:appliance, appliance_set: as)
  end

  def user_key_request(original_request, key)
    request = original_request
    request[:appliance][:user_key_id] = key.id
    request
  end

  def appliance_response
    json_response['appliance']
  end

  def appliances_response
    json_response['appliances']
  end

  def endpoints_response
    json_response['endpoints']
  end

  def start_request(at_config, appliance_set)
    generic_start_request(at_config, appliance_set,
      name: 'my_name', description: 'my_description')
  end

  def generic_start_request(at_config, appliance_set, options = {})
    {
      appliance: {
        configuration_template_id: at_config.id,
        appliance_set_id: appliance_set.id,
        name: options[:name],
        description: options[:description]
      }
    }
  end
end