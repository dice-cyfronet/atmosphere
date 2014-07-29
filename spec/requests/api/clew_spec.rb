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

      let!(:appliance)     { create(:appliance, appliance_set: portal_set) }
      let!(:vm1) { create(:virtual_machine, appliances: [ appliance ]) }


      it 'returns 200' do

        get api("/clew/appliance_instances?appliance_set_type=portal", user)

        #puts "#{response.body}"

        expect(response.status).to eq 200
      end

    end

  end

  describe 'GET /clew/appliance_types', :focus => true do

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/clew/appliance_types")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated' do

      let(:user)  { create(:user) }
      let(:at1)   { create(:filled_appliance_type, author: user) }
      let(:at2)   { create(:appliance_type, visible_to: :all) }

      it 'returns 200' do

        get api("/clew/appliance_types", user)

        expect(response.status).to eq 200

      end
    end

  end


end




