require 'rails_helper'

describe Api::V1::ClewController do
  include ApiHelpers

  describe 'GET /clew/appliance_instances' do

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/clew/appliance_instances")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated' do

      let(:user)           { create(:developer) }
      let(:different_user) { create(:user) }
      let(:admin)          { create(:admin) }

      let!(:portal_set)    { create(:appliance_set, user: user, appliance_set_type: :portal)}
      let!(:workflow1_set) { create(:appliance_set, user: user, appliance_set_type: :workflow)}
      let!(:differnt_user_workflow) { create(:appliance_set, user: different_user) }

      let!(:at)           { create(:appliance_type) }

      let!(:pmt)          { create(:port_mapping_template, appliance_type: at) }
      let!(:endp)         { create(:endpoint, port_mapping_template: pmt) }

      let!(:appl)         { create(:appliance, appliance_set: portal_set, appliance_type: at) }
      let!(:vm1)          { create(:virtual_machine, appliances: [ appl ]) }

      let!(:httpm)        { create(:http_mapping, appliance: appl, port_mapping_template: pmt) }
      let!(:pm)           { create(:port_mapping, port_mapping_template: pmt, virtual_machine: vm1) }


      it 'returns 200' do
        get api("/clew/appliance_instances", user)
        expect(response.status).to eq 200
      end

      it 'returns appropriate response' do
        get api("/clew/appliance_instances", user)
        expect(response.status).to eq 200
        expected_response = {"clew_appliance_instances"=>
                 {"appliances"=>
                      [{"id"=>appl.id,
                        "name"=>appl.name,
                        "appliance_set_id"=>appl.appliance_set_id,
                        "description"=>appl.description,
                        "state"=>appl.state,
                        "state_explanation"=>appl.state_explanation,
                        "amount_billed"=>appl.amount_billed,
                        "prepaid_until"=>appl.prepaid_until.iso8601(3),
                        "port_mapping_templates"=>
                            [{"id"=>pmt.id,
                              "service_name"=>pmt.service_name,
                              "target_port"=>pmt.target_port,
                              "transport_protocol"=>pmt.transport_protocol,
                              "application_protocol"=>pmt.application_protocol,
                              "http_mappings"=>
                                  [{"id"=>httpm.id,
                                    "application_protocol"=>httpm.application_protocol,
                                    "url"=>httpm.url,
                                    "appliance_id"=>httpm.appliance_id,
                                    "port_mapping_template_id"=>httpm.port_mapping_template_id,
                                    "created_at"=>httpm.created_at.iso8601(3),
                                    "updated_at"=>httpm.updated_at.iso8601(3),
                                    "compute_site_id"=>httpm.compute_site_id,
                                    "monitoring_status"=>httpm.monitoring_status}],
                              "endpoints"=>
                                  [{"id"=>endp.id,
                                    "name"=>endp.name,
                                    "description"=>endp.description,
                                    "descriptor"=>endp.descriptor,
                                    "endpoint_type"=>endp.endpoint_type,
                                    "invocation_path"=>endp.invocation_path,
                                    "port_mapping_template_id"=>endp.port_mapping_template_id,
                                    "created_at"=>endp.created_at.iso8601(3),
                                    "updated_at"=>endp.updated_at.iso8601(3),
                                    "secured"=>endp.secured}]}],
                        "virtual_machines"=>
                            [{"id"=>vm1.id,
                              "ip"=>vm1.ip,
                              "state"=>vm1.state,
                              "compute_site"=>
                                  {"id"=>cs.id,
                                   "site_id"=>cs.site_id,
                                   "name"=>cs.name,
                                   "location"=>cs.location,
                                   "site_type"=>cs.site_type,
                                   "technology"=>cs.technology,
                                   "http_proxy_url"=>cs.http_proxy_url,
                                   "https_proxy_url"=>cs.https_proxy_url,
                                   "config"=>"SANITIZED",
                                   "template_filters"=>cs.template_filters,
                                   "active"=>cs.active},
                              "virtual_machine_flavor"=>nil,
                              "port_mappings"=>[{"id"=>pm.id,
                                                 "public_ip"=>pm.public_ip,
                                                 "source_port"=>pm.source_port,
                                                 "port_mapping_template_id"=>pm.port_mapping_template_id,
                                                 "virtual_machine_id"=>pm.virtual_machine_id,
                                                 "created_at"=>pm.created_at.iso8601(3),
                                                 "updated_at"=>pm.updated_at.iso8601(3)}]}]}]}}


        #TODO maybe some appropriate matcher would fit better here

        expect(json_response).to eq expected_response
      end

    end

    def clew_ai_response
      json_response['clew_appliance_instances']
    end

    def cs
      vm1.compute_site
    end

  end

  describe 'GET /clew/appliance_types' do

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/clew/appliance_types")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated' do

      let!(:user) { create(:user) }

      let!(:at1)  { create(:filled_appliance_type, author: user) }
      let!(:at2)  { create(:appliance_type, visible_to: :all) }
      let!(:at3)  { create(:active_appliance_type, author: user) }
      let!(:at4)  { create(:active_appliance_type, visible_to: :all) }

      let!(:act1) { create(:appliance_configuration_template, appliance_type: at1) }
      let!(:act2) { create(:appliance_configuration_template, appliance_type: at2) }
      let!(:act3) { create(:appliance_configuration_template, appliance_type: at3) }
      let!(:act4) { create(:appliance_configuration_template, appliance_type: at4) }

      let!(:flavor)   { create(:flavor) }

      it 'returns 200' do
        get api("/clew/appliance_types", user)
        expect(response.status).to eq 200
      end

      it 'returns appropriate response' do
        get api("/clew/appliance_types", user)

        expect(response.status).to eq 200
        expect(clew_at_response['appliance_types'].size).to eq 2
        expect(clew_at_response['compute_sites'].size).to eq 2
        expect(clew_at_response['appliance_types'][0]).to clew_at_eq at3
        expect(clew_at_response['appliance_types'][1]).to clew_at_eq at4
        expect(clew_at_response['appliance_types'][0]['matched_flavor']).to clew_flavor_eq  flavor
        expect(clew_at_response['appliance_types'][1]['matched_flavor']).to clew_flavor_eq  flavor

        #TODO complete this test to check all the returned fields

      end

    end

    def clew_at_response
      json_response['clew_appliance_types']
    end

  end


end




