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

  expect_it { to belong_to :appliance_type }
  expect_it { to have_many :http_mappings }
  expect_it { to have_many :port_mapping_properties }
  expect_it { to have_many :endpoints }

  expect_it { to validate_numericality_of :target_port }
  expect_it { should_not allow_value(-1).for(:target_port) }

  pending 'should allow many PortMappings'

end
