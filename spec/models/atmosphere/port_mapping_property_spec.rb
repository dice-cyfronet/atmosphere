# == Schema Information
#
# Table name: port_mapping_properties
#
#  id                       :integer          not null, primary key
#  key                      :string(255)      not null
#  value                    :string(255)      not null
#  port_mapping_template_id :integer
#  compute_site_id          :integer
#  created_at               :datetime
#  updated_at               :datetime
#

require 'rails_helper'

describe Atmosphere::PortMappingProperty do

  it { should validate_presence_of :key }
  it { should validate_presence_of :value }

  it { should belong_to :port_mapping_template }
  it { should belong_to :tenant }

  context 'if no tenant' do
    before { allow(subject).to receive(:tenant).and_return(nil) }
    it { should validate_presence_of(:port_mapping_template) }
  end

  context 'if no port_mapping_template' do
    before { allow(subject).to receive(:port_mapping_template).and_return(nil) }
    it { should validate_presence_of(:tenant) }
  end

  context 'if tenant is present' do
    before { allow(subject).to receive(:tenant_id).and_return(1) }
    it 'should require absence of port_mapping_template' do
      expect(subject.port_mapping_template_id).to eq nil
    end
  end

  context 'if port_mapping_template is present' do
    before { allow(subject).to receive(:port_mapping_template_id).and_return(1) }
    it 'should require absence of tenant' do
      expect(subject.tenant_id).to eq nil
    end
  end

  describe '#to_s' do
    subject { create(:port_mapping_property, key: 'key', value: 'value') }

    it 'combine key and value' do
      expect(subject.to_s).to eq 'key value'
    end
  end

  describe 'key uniques' do
    context 'when PMP with key exist' do
      let(:pmt) { create(:port_mapping_template) }
      let(:pmt2) { create(:port_mapping_template) }
      before do
        pmt.port_mapping_properties.create(key: 'key', value: 'value')
      end

      it 'does not allow to create another one with the same PMT and key' do
        expect {
          pmt.port_mapping_properties.create!(key: 'key', value: 'value')
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'allows to create 2 the same PMP for 2 different PMT' do
        expect {
          pmt2.port_mapping_properties.create!(key: 'key', value: 'value')
        }.to_not raise_error
      end
    end
  end
end
