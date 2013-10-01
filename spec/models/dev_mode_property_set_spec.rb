# == Schema Information
#
# Table name: dev_mode_property_sets
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  description       :text
#  shared            :boolean          default(FALSE), not null
#  scalable          :boolean          default(FALSE), not null
#  preference_cpu    :float
#  preference_memory :integer
#  preference_disk   :integer
#  appliance_id      :integer          not null
#  security_proxy_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#

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

  context '#create_from' do
    let(:endpoint1) { build(:endpoint) }
    let(:endpoint2) { build(:endpoint) }

    let(:port_mapping_property1) { build(:pmt_property) }
    let(:port_mapping_property2) { build(:pmt_property) }

    let(:port_mapping1) { create(:port_mapping_template,
        endpoints: [endpoint1, endpoint2],
        port_mapping_properties: [
          port_mapping_property1,
          port_mapping_property2
        ]
      )
    }

    let(:port_mapping2) { create(:port_mapping_template) }

    let(:appliance_type) { create(:filled_appliance_type,
        port_mapping_templates: [port_mapping1, port_mapping2]
      )
    }

    it 'copying appliance_type attributes values' do
      target = DevModePropertySet.create_from(appliance_type)

      expect(target.name).to eq appliance_type.name
      expect(target.description).to eq appliance_type.description
      expect(target.shared).to eq appliance_type.shared
      expect(target.scalable).to eq appliance_type.scalable
      expect(target.preference_cpu).to eq appliance_type.preference_cpu
      expect(target.preference_memory).to eq appliance_type.preference_memory
      expect(target.preference_disk).to eq appliance_type.preference_disk
      expect(target.security_proxy).to eq appliance_type.security_proxy
    end

    it 'copying port_mappings' do
      target = DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates.size).to eq 2
    end

    it 'copying port_mapping endpoints' do
      target = DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates[0].endpoints.size).to eq 2
      expect(target.port_mapping_templates[1].endpoints.size).to eq 0
    end

    it 'copying port_mapping_templates' do
      target = DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates[0].port_mapping_properties.size).to eq 2
      expect(target.port_mapping_templates[1].port_mapping_properties.size).to eq 0
    end
  end
end
