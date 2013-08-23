# == Schema Information
#
# Table name: http_mappings
#
#  id                       :integer          not null, primary key
#  application_protocol     :string(255)      default("http"), not null
#  url                      :string(255)      default(""), not null
#  appliance_id             :integer
#  port_mapping_template_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#

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
