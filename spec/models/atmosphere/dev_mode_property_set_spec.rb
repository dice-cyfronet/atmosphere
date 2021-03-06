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

require 'rails_helper'

describe Atmosphere::DevModePropertySet do
  it { should validate_presence_of :name }

  [:preference_memory, :preference_disk, :preference_cpu].each do |attribute|
    it { should validate_numericality_of attribute }
    it { should_not allow_value(-1).for(attribute) }
  end

  it { should belong_to :appliance }
  it { should validate_presence_of :appliance }

  it { should have_many(:port_mapping_templates).dependent(:destroy) }

  context '#user_id' do
    context 'is associated with appliance set' do
      it 'returns user id of user owning associated appliance set' do
        dev_appl_set = build(:dev_appliance_set)
        dev_appl = build(:appliance, appliance_set: dev_appl_set)
        dev_mode_prop_set = build(:dev_mode_property_set, appliance: dev_appl)
        expect(dev_mode_prop_set.user_id).to eq(dev_appl_set.user_id)
      end
    end
    context 'is not associated with appliance' do
      it 'returns nil' do
        dev_mode_property_set = Atmosphere::DevModePropertySet.new
        expect(dev_mode_property_set.user_id).to be_nil
      end
    end
    context 'is associated with appliance that is not associated with a set' do
      it 'returns nil' do
        appl = Atmosphere::Appliance.new
        dev_mode_property_set =
            Atmosphere::DevModePropertySet.new(appliance: appl)
        expect(dev_mode_property_set.user_id).to be_nil
      end
    end
  end

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
      target = Atmosphere::DevModePropertySet.create_from(appliance_type)

      expect(target.name).to eq appliance_type.name
      expect(target.description).to eq appliance_type.description
      expect(target.shared).to eq appliance_type.shared
      expect(target.scalable).to eq appliance_type.scalable
      expect(target.preference_cpu).to eq appliance_type.preference_cpu
      expect(target.preference_memory).to eq appliance_type.preference_memory
      expect(target.preference_disk).to eq appliance_type.preference_disk
    end

    it 'copying port_mappings' do
      target = Atmosphere::DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates.size).to eq 2
    end

    it 'setting relation between appliance type and port_mappings copy relations into null' do
      target = Atmosphere::DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates[0].appliance_type).to be_nil
      expect(target.port_mapping_templates[1].appliance_type).to be_nil
    end

    it 'copying port_mapping endpoints' do
      target = Atmosphere::DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates[0].endpoints.size).to eq 2
      expect(target.port_mapping_templates[1].endpoints.size).to eq 0
    end

    it 'copying port_mapping_templates' do
      target = Atmosphere::DevModePropertySet.create_from(appliance_type)
      expect(target.port_mapping_templates[0].port_mapping_properties.size).to eq 2
      expect(target.port_mapping_templates[1].port_mapping_properties.size).to eq 0
    end
  end
end
