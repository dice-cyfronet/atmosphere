require 'rails_helper'

describe Atmosphere::Api::V1::ClewController do
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

        appl.reload

        expected_response = {"clew_appliance_instances"=>
                 {"appliances"=>
                      [{"id"=>appl.id,
                        "name"=>appl.name,
                        "appliance_set_id"=>appl.appliance_set_id,
                        "appliance_type_id" => appl.appliance_type_id,
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
                                    "compute_site_id"=>httpm.tenant_id,
                                    "monitoring_status"=>httpm.monitoring_status,
                                    "custom_name"=>httpm.custom_name,
                                    "custom_url"=>httpm.custom_url
                                    }],
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
                                  {"id"=>t.id,
                                   "site_id"=>t.tenant_id,
                                   "name"=>t.name,
                                   "location"=>t.location,
                                   "site_type"=>t.tenant_type,
                                   "technology"=>t.technology,
                                   "http_proxy_url"=>t.http_proxy_url,
                                   "https_proxy_url"=>t.https_proxy_url,
                                   "config"=>"SANITIZED",
                                   "template_filters"=>t.template_filters,
                                   "active"=>t.active},
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

    def t
      vm1.tenant
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
      let!(:fund) { create(:fund) }
      let!(:user) { create(:user, funds: [fund]) }

      let!(:at1)  { create(:filled_appliance_type, author: user) }
      let!(:at2)  { create(:appliance_type, visible_to: :all) }
      let!(:at3)  { create(:active_appliance_type, author: user) }
      let!(:at4)  { create(:active_appliance_type, visible_to: :all) }

      let(:t) { create(:tenant, funds: [fund]) }

      let!(:vmt3) { create(:virtual_machine_template, tenants: [t], appliance_type: at3) }
      let!(:vmt4) { create(:virtual_machine_template, tenants: [t], appliance_type: at4) }

      let!(:act1) { create(:appliance_configuration_template, appliance_type: at1) }
      let!(:act2) { create(:appliance_configuration_template, appliance_type: at2) }
      let!(:act3) { create(:appliance_configuration_template, appliance_type: at3) }
      let!(:act4) { create(:appliance_configuration_template, appliance_type: at4) }

      let!(:flavor)   { create(:flavor, tenant: t) }

      it 'returns 200' do
        get api("/clew/appliance_types", user)
        expect(response.status).to eq 200
      end

      it 'returns appropriate response' do
        get api("/clew/appliance_types", user)

        expect(response.status).to eq 200
        expect(clew_at_response['appliance_types'].size).to eq 2
        expect(clew_at_response['compute_sites'].size).to eq 1
        expect(clew_at_response['appliance_types'][0]).to clew_at_eq at3
        expect(clew_at_response['appliance_types'][1]).to clew_at_eq at4
        expect(clew_at_response['appliance_types'][0]['matched_flavor']).to clew_flavor_eq  flavor
        expect(clew_at_response['appliance_types'][1]['matched_flavor']).to clew_flavor_eq  flavor

        #TODO complete this test to check all the returned fields
      end
    end

    it 'does not return AT with visible_to owner when user is not owner' do
      fund = create(:fund)
      user = create(:user, funds: [fund])
      t = create(:tenant, funds: [fund])
      create(:flavor, tenant: t)

      owned_at = create(:appliance_type, visible_to: :owner, author: user)
      create(:virtual_machine_template,
             tenants: [t], appliance_type: owned_at)
      not_owned_at = create(:appliance_type, visible_to: :owner)
      create(:virtual_machine_template,
             tenants: [t], appliance_type: not_owned_at)

      get api('/clew/appliance_types', user)

      expect(clew_at_response['appliance_types'].size).to eq 1
      expect(clew_at_response['appliance_types'][0]).to clew_at_eq owned_at
    end

    it 'does not reveal virtual machine templates to which the user is not linked via funds' do
      fund = create(:fund)
      user = create(:user, funds: [fund])
      t1 = create(:openstack_with_flavors, funds: [fund])
      t2 = create(:openstack_with_flavors, funds: [])
      at1 = create(:appliance_type, visible_to: :all)
      at2 = create(:appliance_type, visible_to: :all)
      act1 = create(:appliance_configuration_template, appliance_type: at1)
      act2 = create(:appliance_configuration_template, appliance_type: at2)

      vmt1 = create(:virtual_machine_template, appliance_type: at1, tenants: [t1])
      vmt2 = create(:virtual_machine_template, appliance_type: at1, tenants: [t2])
      vmt3 = create(:virtual_machine_template, appliance_type: at1, tenants: [t1, t2])
      vmt4 = create(:virtual_machine_template, appliance_type: at2, tenants: [t2])

      get api('/clew/appliance_types', user)

      expect(clew_at_response['appliance_types'].size).to eq 1
      expect(clew_at_response['appliance_types'][0]['compute_site_ids']).
        to eq [t1.id]
      expect(clew_at_response['compute_sites'].size).to eq 1
      expect(clew_at_response['compute_sites'][0]['id']).to eq t1.id
    end

    it 'skips AT entirely if it has no available vmts through funds' do
      fund1 = create(:fund)
      fund2 = create(:fund)
      user = create(:user, login: 'foobarbazquux', funds: [fund1])
      create(:tenant, funds: [fund1])
      t2 = create(:tenant, funds: [fund2])
      at = create(:appliance_type, visible_to: :all)
      create(:appliance_configuration_template, appliance_type: at)
      create(:virtual_machine_template, appliance_type: at, tenants: [t2])

      get api('/clew/appliance_types', user)

      expect(clew_at_response['appliance_types'].size).to eq 0
      expect(clew_at_response['compute_sites'].size).to eq 0
    end

    it 'skips AT if all of its VMTs reside on inactive tenants' do
      fund = create(:fund)
      user = create(:user, login: 'foobarbazquux', funds: [fund])
      t1 = create(:tenant, active: false, funds: [fund])
      t2 = create(:tenant, active: false, funds: [fund])
      vmt = create(:virtual_machine_template, tenants: [t1, t2])
      at = create(
        :appliance_type,
        visible_to: :all,
        virtual_machine_templates: [vmt]
      )
      create(:appliance_configuration_template, appliance_type: at)

      get api('/clew/appliance_types', user)

      expect(clew_at_response['appliance_types'].size).to eq 0
      expect(clew_at_response['compute_sites'].size).to eq 0
    end

    def clew_at_response
      json_response['clew_appliance_types']
    end
  end
end
