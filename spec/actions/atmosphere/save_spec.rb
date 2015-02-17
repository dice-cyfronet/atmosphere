require 'rails_helper'

describe Atmosphere::Cloud::Save do

  it 'creates new VMT assigned into appliance AT' do
    target_at, save_action = at_and_action

    expect { save_action.execute }.
      to change { Atmosphere::VirtualMachineTemplate.count }.by(1)

    target_at.reload
    expect(target_at.virtual_machine_templates.count).to eq 1
  end

  def at_and_action
    vm = create(:virtual_machine)
    appl = create(:appliance, virtual_machines: [vm])
    target_at = create(:appliance_type)
    save_action = Atmosphere::Cloud::Save.new(appl, target_at)
    allow(Atmosphere::VirtualMachineTemplate).
      to receive(:create_from_vm).
      with(vm).and_return(build(:virtual_machine_template))

    [target_at, save_action]
  end
end
