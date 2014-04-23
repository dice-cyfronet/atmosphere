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

      required_mem = 1024
      let(:cs) { create(:compute_site) }
      let(:cs2) { create(:compute_site) }
      let!(:f1) { create(:virtual_machine_flavor) }
      let!(:f2) { create(:virtual_machine_flavor) }
      let!(:f3) { create(:virtual_machine_flavor, compute_site: cs) }
      let!(:f4) { create(:virtual_machine_flavor, memory: required_mem - 256) }
      let!(:f5) { create(:virtual_machine_flavor, memory: required_mem) }
      let!(:f6) { create(:virtual_machine_flavor, memory: required_mem + 256, compute_site: cs2) }
      let(:at) { create(:appliance_type, preference_memory:required_mem) }

      it 'returns 200' do
        get api('/virtual_machine_flavors', user)
        expect(response.status).to eq 200
      end

      it 'returns all flavors when no filters are specified' do
        get api('/virtual_machine_flavors', user)
        flavors = fls_response
        expect(flavors.size).to eq VirtualMachineFlavor.count
      end

      context 'filters validation' do
        it "returns 409 conflict for conflicting filters" do
          get api('/virtual_machine_flavors?appliance_configuration_instance_id=1&appliance_type_id=1', user)
          expect(response.status).to eq 409
        end

        it "allows appliance type filters and requirements" do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}&compute_site_id=#{cs.id}", user)
          expect(response.status).to eq 200
        end

        it "returns 200 for empty filters" do
          get api('/virtual_machine_flavors', user)
          expect(response.status).to eq 200
        end
      end

      context 'when filter defined for compute site' do
        
        it "returns flavors at given cs only" do
          get api("/virtual_machine_flavors?compute_site_id=#{cs.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 1
          expect(flavors.first['compute_site_id']).to eq cs.id
        end
      end

      context 'when requirements filter defined' do

        it "returns flavors with memory grater or equal to specified" do          
          get api("/virtual_machine_flavors?memory=#{required_mem}", user)
          flavors = fls_response
          expect(flavors.size).to be >= 2
          flavors.each{|f| expect(f['memory']).to be >= required_mem }
        end

        it "returns flavors with memory grater or equal to specified and available at given cs" do
          get api("/virtual_machine_flavors?memory=#{required_mem}&compute_site_id=#{cs2.id}", user)
          flavors = fls_response
          expect(flavors.size).to be >= 1
          flavors.each{|f|
            expect(f['memory']).to be >= required_mem
            expect(f['compute_site_id']).to eq cs2.id
          }
        end
      end

      context 'filter for appliance type defined' do

        it "returns empty list if AT does not exist" do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id + 1}", user)
          flavors = fls_response
          expect(flavors.size).to eq 0
        end

        it "returns empty list if there are no templates for AT" do
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 0
        end

        it "returns one flavor with memory greater or equal to preference memory specified in at" do
          tmpl = create(:virtual_machine_template, appliance_type: at, compute_site: cs2, state: 'active')
          get api("/virtual_machine_flavors?appliance_type_id=#{at.id}", user)
          flavors = fls_response
          expect(flavors.size).to eq 1
          fl = flavors.first
          expect(fl['memory']).to be >= required_mem
          expect(fl['compute_site_id']).to eq tmpl.compute_site_id
        end

        context 'filter for cs specified' do
          it "applies compute site filtering" do
            tmpl = create(:virtual_machine_template, appliance_type: at, compute_site: cs2, state: 'active')
            get api("/virtual_machine_flavors?appliance_type_id=#{at.id}&compute_site_id=#{cs2.id + 1}", user)
            flavors = fls_response
            expect(flavors.size).to eq 0
          end

        end

      end

      context 'filter for appliance configuration instance specified' do
        let(:aci) { create(:appliance_configuration_instance) }
        
        it "returns 404 if config instance does not exist" do
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id + 1}", user)
          expect(response.status).to eq 404
        end

        it "returns 404 if aci does not have a config template" do
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id}", user)
          expect(response.status).to eq 404
        end

        it "returns one flavor with memory greater or equal to preference memory specified in at associated with config" do
          tmpl = create(:virtual_machine_template, appliance_type: at, compute_site: cs2, state: 'active')
          config_tmpl = create(:appliance_configuration_template, appliance_configuration_instances: [aci], appliance_type: at)
          get api("/virtual_machine_flavors?appliance_configuration_instance_id=#{aci.id}", user)
          expect(response.status).to eq 200
          flavors = fls_response
          expect(flavors.size).to eq 1
          fl = flavors.first
          expect(fl['memory']).to be >= required_mem
        end
      end

    end

  end

  def fls_response
    json_response['virtual_machine_flavors']
  end

end