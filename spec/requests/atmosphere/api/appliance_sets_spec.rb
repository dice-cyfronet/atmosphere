require 'rails_helper'

describe Atmosphere::Api::V1::ApplianceSetsController do
  include ApiHelpers

  before do
    allow(Atmosphere::Optimizer.instance).to receive(:run)
  end

  let(:user)           { create(:developer) }
  let(:different_user) { create(:user) }
  let(:admin)          { create(:admin) }

  let!(:portal_set)    { create(:appliance_set, user: user, appliance_set_type: :portal)}
  let!(:workflow1_set) { create(:appliance_set, user: user, appliance_set_type: :workflow)}
  let!(:differnt_user_workflow) { create(:appliance_set, user: different_user) }

  describe 'GET /appliance_sets' do
    let!(:workflow2_set)   { create(:appliance_set, user: user, appliance_set_type: :workflow)}
    let!(:development_set) { create(:appliance_set, user: user, appliance_set_type: :development)}

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/appliance_sets')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/appliance_sets', user)
        expect(response.status).to eq 200
      end

      it 'returns user appliance sets' do
        get api('/appliance_sets', user)
        expect(ases_response).to be_an Array
        expect(ases_response.size).to eq 4

        expect(ases_response[0]).to appliance_set_eq portal_set
        expect(ases_response[1]).to appliance_set_eq workflow1_set
        expect(ases_response[2]).to appliance_set_eq workflow2_set
        expect(ases_response[3]).to appliance_set_eq development_set
      end

      context 'search' do
        it 'returns only workflow appliance sets' do
          get api('/appliance_sets?appliance_set_type=workflow', user)
          expect(ases_response.size).to eq 2
          expect(ases_response[0]).to appliance_set_eq workflow1_set
          expect(ases_response[1]).to appliance_set_eq workflow2_set
        end
      end
    end

    context 'when authenticated as admin' do
      it 'returns all sets for admin with all flag set to true' do
        get api('/appliance_sets?all=true', admin)
        expect(ases_response.size).to eq 5
      end
    end
  end

  describe 'POST /appliances_sets' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api('/appliance_sets')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:non_developer) { create(:user) }
      let(:new_appliance_set) do
        { appliance_set: { name: 'my name', appliance_set_type: :workflow } }
      end

      it 'returns 201 Created on success' do
        post api('/appliance_sets', user), new_appliance_set
        expect(response.status).to eq 201
      end

      it 'creates second workflow appliance set' do
        expect {
          post api('/appliance_sets', user), new_appliance_set
          expect(as_response['id']).to_not be_nil
          expect(as_response['name']).to eq new_appliance_set[:appliance_set][:name]
          expect(as_response['appliance_set_type']).to eq new_appliance_set[:appliance_set][:appliance_set_type].to_s
        }.to change { Atmosphere::ApplianceSet.count }.by(1)
      end

      it 'does not allow to create second portal appliance set' do
        expect {
          post api('/appliance_sets', user), {appliance_set: {name: 'second portal', appliance_set_type: :portal}}
          expect(response.status).to eq 409
        }.to change { Atmosphere::ApplianceSet.count }.by(0)
      end

      it 'does not allow to create second development appliance set' do
        create(:appliance_set, user: user, appliance_set_type: :development)
        expect {
          post api('/appliance_sets', user), {appliance_set: {name: 'second portal', appliance_set_type: :development}}
          expect(response.status).to eq 409
        }.to change { Atmosphere::ApplianceSet.count }.by(0)
      end

      it 'does not allow create development appliance set for non developer' do
        post api('/appliance_sets', non_developer), {appliance_set: {name: 'devel', appliance_set_type: :development}}
        expect(response.status).to eq 403
      end

      context 'optimization policy and appliances are specified' do

        let!(:at_1) { create(:appliance_type, visible_to: :all)}
        let!(:conf_tmpl_1) { create(:appliance_configuration_template, appliance_type: at_1) }
        let!(:at_2) { create(:appliance_type, visible_to: :all)}
        let!(:conf_tmpl_2) { create(:appliance_configuration_template, appliance_type: at_2) }
        let(:cs) { create(:compute_site) }
        let(:tmpl_1) { create(:virtual_machine_template, appliance_type: at_1, compute_site: cs) }
        let(:tmpl_2) { create(:virtual_machine_template, appliance_type: at_2, compute_site: cs) }

        AS_NAME = 'AS with appliances and optimization policy'

        let!(:appliances_params) {
          [
            {configuration_template_id: conf_tmpl_1.id, params: {a: 'A'}, vms: [{cpu: 1, mem: 512, compute_site_ids: [1]}]},
            {configuration_template_id: conf_tmpl_2.id, params: {b: 'B'}, vms: [{cpu: 1, mem: 512, compute_site_ids: [1]}]}
          ]

        }


        before(:each) do
          params = {appliance_set: {name: AS_NAME, appliance_set_type: :workflow, optimization_policy: :manual, appliances: appliances_params}}
          post api('/appliance_sets', non_developer), params
        end

        it 'creates AS with optimization policy' do
          expect(created_as.optimization_policy).to eq 'manual'
        end

        it 'creates AS with appliances' do
          expect(created_as.appliances.count).to eq appliances_params.size
        end

        it 'calls optimizer for each appliance of created AS' do
          expect(Atmosphere::Optimizer.instance).to have_received(:run).exactly(created_as.appliances.count).times
        end

        def created_as
          Atmosphere::ApplianceSet.find(as_response['id'])
        end

      end

    end
  end

  describe 'GET /appliance_sets/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/appliance_sets/#{portal_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        get api("/appliance_sets/#{portal_set.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns portal appliance set' do
        get api("/appliance_sets/#{portal_set.id}", user)
        expect(as_response).to appliance_set_eq portal_set
      end
    end
  end

  describe 'PUT /appliance_sets/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        put api("/appliance_sets/#{portal_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:update_request) do
        { appliance_set: { name: 'updated', priority: 99 } }
      end
      it 'returns 200 on success' do
        put api("/appliance_sets/#{portal_set.id}", user), update_request
        expect(response.status).to eq 200
      end

      it 'changes name and priority' do
        put api("/appliance_sets/#{portal_set.id}", user), update_request
        set = Atmosphere::ApplianceSet.find(portal_set.id)
        expect(set.name).to eq 'updated'
        expect(set.priority).to eq 99
      end

      it 'does not change appliance set type' do
        put api("/appliance_sets/#{portal_set.id}", user), {appliance_set: {appliance_set_type: :workflow}}
        set = Atmosphere::ApplianceSet.find(portal_set.id)
        expect(set.appliance_set_type).to eq 'portal'
      end
    end
  end

  describe 'DELETE /appliance_sets/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        delete api("/appliance_sets/#{portal_set.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 on success' do
        delete api("/appliance_sets/#{portal_set.id}", user)
        expect(response.status).to eq 200
      end

      it 'deletes appliance set' do
        expect {
          delete api("/appliance_sets/#{portal_set.id}", user)
        }.to change { Atmosphere::ApplianceSet.count }.by(-1)
      end

      it 'returns 403 when deleting not owned appliance set' do
        expect {
          delete api("/appliance_sets/#{portal_set.id}", different_user)
          expect(response.status).to eq 403
        }.to change { Atmosphere::ApplianceSet.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'deletes appliance set even when no set owner' do
        delete api("/appliance_sets/#{portal_set.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  def ases_response
    json_response['appliance_sets']
  end

  def as_response
    json_response['appliance_set']
  end
end