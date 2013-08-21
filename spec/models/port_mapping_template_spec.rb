require 'spec_helper'

describe PortMappingTemplate do

  expect_it { to validate_presence_of :service_name }
  expect_it { to validate_presence_of :target_port }
  expect_it { to validate_presence_of :application_protocol }
  expect_it { to validate_presence_of :transport_protocol }

  # TODO make 'if' conditional validation test
  #expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(http https http_https)) }
  expect_it { to ensure_inclusion_of(:transport_protocol).in_array(%w(tcp udp)) }

  it 'should set proper default values' do
    # It seems we should use strings, not symbols here - perhaps this makes some kind of round-trip to DB?
    expect(subject.application_protocol).to eql 'http_https'
    expect(subject.transport_protocol).to eql 'tcp'
  end

  expect_it { to belong_to :appliance_type }

  pending 'should allow many Endpoints'
  pending 'should allow many PortMappings'
  pending 'should allow many HttpMappings'
  pending 'should allow one Appliance'
  pending 'should allow many PortMappingProperties'

end
