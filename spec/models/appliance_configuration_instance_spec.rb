# == Schema Information
#
# Table name: appliance_configuration_instances
#
#  id                                  :integer          not null, primary key
#  payload                             :text
#  appliance_configuration_template_id :integer
#  created_at                          :datetime
#  updated_at                          :datetime
#

require 'spec_helper'

describe ApplianceConfigurationInstance do
  expect_it { to have_many(:appliances) }
  expect_it { to belong_to(:appliance_configuration_template) }

  context '#create_payload' do
    let(:static_config_template) { 'static payload' }
    let(:dynamic_config_template) { 'dynamic payload #{param1} #{param2} #{param3}' }

    it 'creates static payload' do
      subject.create_payload(static_config_template)
      expect(subject.payload).to eq static_config_template
    end

    it 'creates dynamic payload' do
      subject.create_payload(dynamic_config_template, {'param1' => 'a', 'param2' => 'b', 'param3' => 'c'})

      expect(subject.payload).to eq 'dynamic payload a b c'
    end
  end
end
