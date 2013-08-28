require 'spec_helper'

describe DevModePropertySet do
  expect_it { to validate_presence_of :name }

  [:preference_memory, :preference_disk, :preference_cpu].each do |attribute|
    expect_it { to validate_numericality_of attribute }
    expect_it { should_not allow_value(-1).for(attribute) }
  end

  expect_it { to belong_to :security_proxy }

  expect_it { to belong_to :appliance }
  expect_it { to validate_presence_of :appliance }

  expect_it { to have_many(:port_mapping_templates).dependent(:destroy) }
end
