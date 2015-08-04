require 'rails_helper'

describe Atmosphere::Api::V1::ActionsController do
  include ApiHelpers

  describe 'GET /actions' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/actions')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated' do
      let(:optimizer) { double('optimizer') }

      before do
        expect(Atmosphere::Optimizer).
          to receive(:instance).at_least(:once) { optimizer }

        expect(optimizer).to receive(:run).at_least(:once).with(anything)
      end

      let!(:message) { 'message123' }

      let!(:user) { create(:user) }
      let!(:appliance_set) { create(:appliance_set, user: user) }
      let!(:appliance) { create(:appliance, appliance_set: appliance_set) }

      let!(:user2) { create(:user) }
      let!(:appliance_set2) { create(:appliance_set, user: user2) }
      let!(:appliance2) { create(:appliance, appliance_set: appliance_set2) }

      let!(:action_log) { create(:action_log, message: message) }
      let!(:action) do
        create(:action,
               appliance: appliance,
               action_logs: [action_log])
      end

      let!(:other_action) { create(:action, appliance: appliance2) }

      it 'returns 200 Success' do
        get api('/actions', user)
        expect(response.status).to eq 200
      end

      it 'returns authorized resources' do
        get api('/actions', user)
        expect(actions_response.size).to eq 1
        expect(actions_response[0]['id']).to eq action.id
        expect(actions_response[0]['appliance_id']).to eq action.appliance_id
      end

      it 'returns correct logs' do
        get api('/actions', user)

        logs = actions_response[0]['action_logs']
        first_log = logs[0]

        expect(logs.size).to eq 1
        expect(first_log['id']).to eq action_log.id
        expect(first_log['log_level']).to eq action_log.log_level
        expect(first_log['message']).to eq action_log.message
      end
    end
  end

  def action_response
    json_response['action']
  end

  def actions_response
    json_response['actions']
  end
end
