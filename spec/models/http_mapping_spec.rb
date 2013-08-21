require 'spec_helper'

describe HttpMapping do
  expect_it { to validate_presence_of :url }
  expect_it { to validate_presence_of :application_protocol }

  expect_it { to ensure_inclusion_of(:application_protocol).in_array(%w(http https)) }

  it 'should set proper default values' do
    expect(subject.application_protocol).to eql 'http'
    expect(subject.url).to eql ''
  end

  expect_it { to belong_to :appliance }
  expect_it { to validate_presence_of :appliance }

  expect_it { to belong_to :port_mapping_template }
  expect_it { to validate_presence_of :port_mapping_template }
end
