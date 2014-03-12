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

require 'spec_helper'

describe PortMappingProperty do

  expect_it { to validate_presence_of :key }
  expect_it { to validate_presence_of :value }

  expect_it { to belong_to :port_mapping_template }
  expect_it { to belong_to :compute_site }

  context 'if no compute_site' do
    before { subject.stub(:compute_site) { nil } }
    expect_it { to validate_presence_of(:port_mapping_template) }
  end

  context 'if no port_mapping_template' do
    before { subject.stub(:port_mapping_template) { nil } }
    expect_it { to validate_presence_of(:compute_site) }
  end

  context 'if compute_site is present' do
    before { subject.stub(:compute_site_id) { 1 } }
    it 'should require absence of port_mapping_template' do
      expect(subject.port_mapping_template_id).to eq nil
    end
  end

  context 'if port_mapping_template is present' do
    before { subject.stub(:port_mapping_template_id) { 1 } }
    it 'should require absence of compute_site' do
      expect(subject.compute_site_id).to eq nil
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
