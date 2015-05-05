require 'rails_helper'

describe Atmosphere::FlavorOSFamily do
  let(:flavor) { create(:flavor) }
  let(:os_family) { Atmosphere::OSFamily.first }
  let(:at) { create(:appliance_type, os_family: os_family) }
  let(:vmt) { create(:virtual_machine_template, appliance_type: at) }

  it 'prevents destroy of billed cost setting' do
    create(:virtual_machine,
           managed_by_atmosphere: true,
           virtual_machine_flavor: flavor,
           source_template: vmt)
    flavor.set_hourly_cost_for(os_family, 100)
    expect(Atmosphere::FlavorOSFamily.count).to eq 1
    fosf = Atmosphere::FlavorOSFamily.first
    expect{ fosf.destroy }.to change{ Atmosphere::FlavorOSFamily.count }.by(0)
    fosf.destroy
    expect(fosf.errors).not_to be_empty
    expect(fosf.errors.full_messages.first).
      to eq I18n.t('flavor_os_family.running_vms')
  end

  it 'ignores cost settings for unmanaged VMs' do
    create(:virtual_machine,
           managed_by_atmosphere: false,
           virtual_machine_flavor: flavor,
           source_template: vmt)
    flavor.set_hourly_cost_for(os_family, 100)
    expect(Atmosphere::FlavorOSFamily.count).to eq 1
    expect{ Atmosphere::FlavorOSFamily.first.destroy }.
      to change{ Atmosphere::FlavorOSFamily.count }.by(-1)
  end
end
