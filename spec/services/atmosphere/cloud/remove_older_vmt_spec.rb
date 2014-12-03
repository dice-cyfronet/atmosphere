require 'rails_helper'

describe Atmosphere::Cloud::RemoveOlderVmt do

  it 'removes only older VMTs' do
    at = create(:appliance_type)
    create(:virtual_machine_template, appliance_type: at)
    selected_vmt = create(:virtual_machine_template, appliance_type: at)
    new_vmt = create(:virtual_machine_template, appliance_type: at)
    action = Atmosphere::Cloud::RemoveOlderVmt.new(selected_vmt)

    action.execute
    at.reload

    expect(at.virtual_machine_templates.count).to eq 2
    expect(at.virtual_machine_templates).to include(selected_vmt, new_vmt)
  end
end
