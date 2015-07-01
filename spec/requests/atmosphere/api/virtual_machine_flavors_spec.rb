require 'rails_helper'

describe Atmosphere::Api::V1::VirtualMachineFlavorsController do
  include ApiHelpers
  include VmtOnTHelpers

  let(:user) { create(:user) }

  describe 'GET /virtual_machine_flavors' do

    context 'when not authenticated' do

      it 'returns 401 Unauthorized error' do
          get api('/virtual_machine_flavors')
          expect(response.status).to eq 401
        end

    end

    context 'when authenticated' do

      required_mem = 1024
      let(:t) { create(:tenant) }
      let(:t2) { create(:tenant) }
      let!(:f1) { create(:virtual_machine_flavor) }
      let!(:f2) { create(:virtual_machine_flavor) }
      let!(:f3) { create(:virtual_machine_flavor, tenant: t) }
      let!(:f4) { create(:virtual_machine_flavor, memory: required_mem - 256) }
      let!(:f5) { create(:virtual_machine_flavor, memory: required_mem) }
      let!(:f6) { create(:virtual_machine_flavor, memory: required_mem + 256, tenant: t2) }
      let(:at) { create(:appliance_type, preference_memory:required_mem) }

      it 'returns 200' do
        get api('/virtual_machine_flavors', user)
        expect(response.status).to eq 200
      end

      it 'returns all flavors when no filters are specified' do
        get api('/virtual_machine_flavors', user)
        flavors = fls_response
        expect(flavors.size).to eq Atmosphere::VirtualMachineFlavor.count
      end

      it 'filters flavors if id param is provided' do
        get api("/virtual_machine_flavors?id=#{f1.id},#{f2.id}", user)
        flavors = fls_response
        expect(flavors.size).to eq 2
        expect([flavors.first['id'], flavors.last['id']]).to include(f1.id, f2.id)
      end

      context 'params in invalid format' do
        it 'returns 422 status' do
          ['hdd', 'memory', 'cpu', 'compute_site_id', 'appliance_type_id', 'appliance_configuration_instance_id'].each do |param_name|
            get api("/virtual_machine_flavors?#{param_name}=INVALID", user)
            expect(response.status).to eq 422
            expect(json_response)
              .to eq error_response(
                "Invalid parameter format for #{param_name}", 'general'
              )
          end
        end
      end

      context 'filters validation' do
        it "returns 409 conflict for conflicting filters" do
          get api('/virtual_machine_flavors?appliance_configuration_instance_id=1&appliance_type_id=1', user)
          expect(response.status).to eq 409
        end

        it 'allows appliance type filters and requirements' do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}&compute_site_id=#{t.id}", user)
          expect(response.status).to eq 200
        end

        it 'returns 200 for empty filters' do
          get api('/virtual_machine_flavors', user)
          expect(response.status).to eq 200
        end
      end

      context 'when filter defined for compute site' do

        it 'returns flavors at given compute site only' do
          get api("/virtual_machine_flavors?compute_site_id=#{t.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 1
          expect(flavors.first['compute_site_id']).to eq t.id
        end
      end

      context 'when requirements filter defined' do

        it 'returns flavors with memory grater or equal to specified' do
          get api("/virtual_machine_flavors?memory=#{required_mem}", user)
          flavors = fls_response
          expect(flavors.size).to be >= 2
          flavors.each{|f| expect(f['memory']).to be >= required_mem }
        end

        it 'returns flavors with memory grater or equal to specified and available at given compute site' do
          get api("/virtual_machine_flavors?memory=#{required_mem}&compute_site_id=#{t2.id}", user)
          flavors = fls_response
          expect(flavors.size).to be >= 1
          flavors.each{|f|
            expect(f['memory']).to be >= required_mem
            expect(f['compute_site_id']).to eq t2.id
          }
        end

        context 'limit specified' do
          it "returns no more than limit flavors" do
            create(:virtual_machine_flavor, memory: required_mem + 512, tenant: t2)
            create(:virtual_machine_flavor, memory: required_mem + 1024, tenant: t2)
            n = 2
            get api("/virtual_machine_flavors?memory=#{required_mem}&compute_site_id=#{t2.id}&limit=#{n}", user)
            flavors = fls_response
            expect(flavors.size).to be <= n
          end

          it 'ignores limit if it is not grater or equal 1' do
            create(:virtual_machine_flavor, memory: required_mem + 512, tenant: t2)
            create(:virtual_machine_flavor, memory: required_mem + 1024, tenant: t2)
            n = -2
            get api("/virtual_machine_flavors?memory=#{required_mem}&compute_site_id=#{t2.id}&limit=#{n}", user)
            flavors = fls_response
            expect(flavors.size).to be >= 0
          end
        end
      end

      context 'filter for appliance type defined' do

        it 'returns empty list if AT does not exist' do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id + 1}", user)
          flavors = fls_response
          expect(flavors.size).to eq 0
        end

        it 'returns empty list if there are no templates for AT' do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 0
        end

        it 'returns one flavor with memory greater or equal to preference memory specified in at' do
          tmpl = create(:virtual_machine_template, appliance_type: at, tenant: t2, state: 'active')
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 1
          fl = flavors.first
          expect(fl['memory']).to be >= required_mem
          expect(fl['compute_site_id']).to eq tmpl.tenant_id
        end

        it 'returns only active flavors when asking about AT flavor chosen by optimizer' do
          inactive_t, inactive_vmt = vmt_on_tenant(t_active: false)
          active_t, active_vmt = vmt_on_tenant(t_active: true)
          create(:flavor, tenant: inactive_t)
          create(:flavor, tenant: active_t)
          at_with_2_vmt = create(:appliance_type,
            virtual_machine_templates: [inactive_vmt, active_vmt])

          get api("/virtual_machine_flavors?appliance_type_id=#{at_with_2_vmt.id}", user)
          response = fls_response

          expect(response.size).to eq 1
          first = response.first
          expect(first['active']).to be_truthy
          expect(first['compute_site_id']).to eq active_t.id
        end

        context 'reqiurements specified' do

          it 'returns one flavor' do
            create(:virtual_machine_template, appliance_type: at, tenant: t, state: 'active')
            get api("virtual_machine_flavors?cpu=1&memory=1024&hdd=5&appliance_type_id=#{at.id}", user)
            flavors = fls_response
            expect(flavors.size).to eq 1
          end
        end

        context 'filter for compute site specified' do
          it 'applies compute site filtering' do
            create(:virtual_machine_template, appliance_type: at, tenant: t2, state: 'active')
            get api("/virtual_machine_flavors?appliance_type_id=#{at.id}&compute_site_id=#{t2.id + 1}", user)
            flavors = fls_response
            expect(flavors.size).to eq 0
          end
        end
      end

      context 'filter for appliance configuration instance specified' do
        let(:aci) { create(:appliance_configuration_instance) }

        it 'returns 404 if config instance does not exist' do
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id + 1}", user)
          expect(response.status).to eq 404
        end

        it 'returns 404 if aci does not have a config template' do
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id}", user)
          expect(response.status).to eq 404
        end

        it 'returns one flavor with memory greater or equal to preference specified in at associated with config' do
          create(:virtual_machine_template, appliance_type: at, tenant: t2, state: 'active')
          config_tmpl = create(:appliance_configuration_template, appliance_configuration_instances: [aci], \
            appliance_type: at)
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id}", user)
          expect(response.status).to eq 200
          flavors = fls_response
          expect(flavors.size).to eq 1
          fl = flavors.first
          expect(fl['memory']).to be >= required_mem
        end

        it 'returns only active flavors when asking about AT flavor chosen by optimizer' do
          inactive_t, inactive_vmt = vmt_on_tenant(t_active: false)
          active_t, active_vmt = vmt_on_tenant(t_active: true)
          create(:flavor, tenant: inactive_t)
          create(:flavor, tenant: active_t)
          at_with_2_vmt = create(:appliance_type,
            virtual_machine_templates: [inactive_vmt, active_vmt])
          config_tmpl = create(:appliance_configuration_template,
              appliance_configuration_instances: [aci],
              appliance_type: at_with_2_vmt
            )

          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id}", user)
          response = fls_response

          expect(response.size).to eq 1
          first = response.first
          expect(first['active']).to be_truthy
          expect(first['compute_site_id']).to eq active_t.id
        end
      end
    end
  end

  def fls_response
    json_response['virtual_machine_flavors']
  end

end
