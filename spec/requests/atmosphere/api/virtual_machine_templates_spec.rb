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
        let(:fund)  { create(:fund) }
        let(:user)  { create(:user, funds: [fund]) }
        let(:tenant)  { create(:tenant, funds: [fund]) }

        it 'returns 200 Success' do
          get api('/virtual_machine_templates', user)
          expect(response.status).to eq 200
        end

        it 'returns VMTs details' do
          at = create(:appliance_type, visible_to: :all)
          vmt1 = create(:managed_vmt, appliance_type: at, tenants: [tenant])
          vmt2 = create(:managed_vmt, appliance_type: at, tenants: [tenant])

          get api('/virtual_machine_templates', user)

          expect(vmts.length).to eq 2
          expect(vmts[0]).to vmt_eq vmt1
          expect(vmts[1]).to vmt_eq vmt2
        end

        it 'returns searched data' do
          at = create(:appliance_type, visible_to: :all)
          vmt1 = create(:managed_vmt, appliance_type: at, tenants: [tenant])
          vmt2 = create(:managed_vmt, appliance_type: at, tenants: [tenant])

          get api("/virtual_machine_templates?id_at_site=#{vmt2.id_at_site}", user)

          expect(vmts.length).to eq 1
          expect(vmts[0]).to vmt_eq vmt2
        end

        context 'when not authorized through funds' do

          before do
            @other_tenant = create(:tenant, funds: [])
            @at = create(:appliance_type, visible_to: :all)
            @vmt1 = create(:managed_vmt, appliance_type: @at, tenants: [tenant])
            @vmt2 = create(:managed_vmt, appliance_type: @at, tenants: [@other_tenant])
          end

          it 'hides unauthorized VMTs from regular users' do
            get api('/virtual_machine_templates', user)

            expect(vmts.length).to eq 1
            expect(vmts[0]).to vmt_eq @vmt1
          end

          it 'reveals unauthorized VMTs to admins' do
            admin = create(:user, funds: [], roles: [:admin])

            get api('/virtual_machine_templates', admin)

            expect(vmts.length).to eq 2
            expect(vmts[0]).to vmt_eq @vmt1
            expect(vmts[1]).to vmt_eq @vmt2
          end
        end
      end
    end
  end

  def vmts
    json_response['virtual_machine_templates']
  end
end
