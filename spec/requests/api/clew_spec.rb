require 'rails_helper'

describe Api::V1::ClewController do
  include ApiHelpers

  describe 'GET /appliances' do

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

      let!(:appliance)     { create(:appliance, appliance_set: portal_set) }
      let!(:vm1) { create(:virtual_machine, appliances: [ appliance ]) }


      it 'returns 200 Unauthorized error' do

        get api("/clew/appliance_instances?appliance_set_type=portal", user)

        puts "#{response.body}"

        expect(response.status).to eq 200
      end
    end


  end

end




