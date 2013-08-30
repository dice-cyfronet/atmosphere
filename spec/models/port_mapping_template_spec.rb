# == Schema Information
#
# Table name: port_mapping_templates
#
#  id                   :integer          not null, primary key
#  transport_protocol   :string(255)      default("tcp"), not null
#  application_protocol :string(255)      default("http_https"), not null
#  service_name         :string(255)      not null
#  target_port          :integer          not null
#  appliance_type_id    :integer          not null
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe PortMappingTemplate do

  subject { FactoryGirl.create(:port_mapping_template) }

  expect_it { to be_valid }

  expect_it { to validate_presence_of :service_name }
  expect_it { to validate_presence_of :target_port }
  expect_it { to validate_presence_of :application_protocol }
  expect_it { to validate_presence_of :transport_protocol }

  expect_it { to ensure_inclusion_of(:transport_protocol).in_array(%w(tcp udp)) }

  context 'if transport_protocol is tcp' do
    before { subject.stub(:transport_protocol) { 'tcp' } }
    expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(http https http_https)) }
  end

  context 'if transport_protocol is udp' do
    before { subject.stub(:transport_protocol) { 'udp' } }
    expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(none)) }
  end

  it 'should set proper default values' do
    # It seems we should use strings, not symbols here - perhaps this makes some kind of round-trip to DB?
    expect(subject.application_protocol).to eql 'http_https'
    expect(subject.transport_protocol).to eql 'tcp'
  end

  expect_it { to have_many :http_mappings }
  expect_it { to have_many :port_mappings }
  expect_it { to have_many(:port_mapping_properties).dependent(:destroy) }
  expect_it { to have_many(:endpoints).dependent(:destroy) }

  expect_it { to validate_numericality_of :target_port }
  expect_it { should_not allow_value(-1).for(:target_port) }

  expect_it { to validate_uniqueness_of(:target_port).scoped_to(:appliance_type_id) }
  expect_it { to validate_uniqueness_of(:service_name).scoped_to(:appliance_type_id) }

  expect_it { to belong_to :appliance_type }
  expect_it { to belong_to :dev_mode_property_set }

  context 'if no appliance_type' do
    before { subject.stub(:appliance_type) { nil } }
    expect_it { to validate_presence_of(:dev_mode_property_set) }
  end

  context 'if no dev_mode_property_set' do
    before { subject.stub(:dev_mode_property_set) { nil } }
    expect_it { to validate_presence_of(:appliance_type) }
  end

  # Uncomment 2 bellow tests when this PR is acceptedhttps://github.com/thoughtbot/shoulda-matchers/pull/331 and than "belongs_to appliance_type or dev_mode_property_set" context can be removed

  # context 'if appliance_type is present' do
  #   before { subject.stub(:appliance_type_id) { 1 } }
  #   expect_it { to validate_abesence_of(:dev_mode_property_set) }
  # end

  # context 'if dev_mode_property_set is present' do
  #   before { subject.stub(:dev_mode_property_set_id) { 1 } }
  #   expect_it { to validate_abesence_of(:appliance_type) }
  # end

  context 'belongs_to appliance_type or dev_mode_property_set' do
    let(:appliance_type) { create(:appliance_type) }
    let(:dev_mode_property_set) { create(:dev_mode_property_set) }
    let(:pmt) { create(:port_mapping_template, appliance_type: appliance_type, dev_mode_property_set: nil) }
    let(:dev_pmt) { create(:port_mapping_template, appliance_type: nil, dev_mode_property_set: dev_mode_property_set) }

    it 'is valid if belongs only to appliance_type' do
      expect(pmt).to be_valid
    end

    it 'is valid if belongs only to dev_mode_property_set' do
      expect(dev_pmt).to be_valid
    end

    it 'is not valid if belongs to nothing' do
      not_belonging = build(:port_mapping_template, appliance_type: nil, dev_mode_property_set: nil)
      expect(not_belonging).to_not be_valid
    end

    it 'cannot belong int both' do
      pmt.dev_mode_property_set = dev_mode_property_set
      expect(pmt).to_not be_valid

      dev_pmt.appliance_type = appliance_type
      expect(dev_pmt).to_not be_valid
    end
  end
end
