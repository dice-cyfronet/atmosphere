require 'rails_helper'

describe Atmosphere::Api::V1::VirtualMachineTemplatesController do
  include ApiHelpers

  describe 'GET /virtual_machine_templates' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/virtual_machine_templates')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated' do
      context 'as user' do
        let(:user)  { create(:user) }

        it 'returns 200 Success' do
          get api('/virtual_machine_templates', user)
          expect(response.status).to eq 200
        end

        it 'returns VMTs details' do
          at = create(:appliance_type, visible_to: :all)
          vmt1 = create(:managed_vmt, appliance_type: at)
          vmt2 = create(:managed_vmt, appliance_type: at)

          get api('/virtual_machine_templates', user)

          expect(vmts.length).to eq 2
          expect(vmts[0]).to vmt_eq vmt1
          expect(vmts[1]).to vmt_eq vmt2
        end

        it 'returns searched data' do
          at = create(:appliance_type, visible_to: :all)
          vmt1 = create(:managed_vmt, appliance_type: at)
          vmt2 = create(:managed_vmt, appliance_type: at)

          get api("/virtual_machine_templates?id_at_site=#{vmt2.id_at_site}", user)

          expect(vmts.length).to eq 1
          expect(vmts[0]).to vmt_eq vmt2
        end
      end
    end
  end

  def vmts
    json_response['virtual_machine_templates']
  end
end
