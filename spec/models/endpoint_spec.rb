# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  description              :text
#  descriptor               :text(16777215)
#  endpoint_type            :string(255)      default("ws"), not null
#  port_mapping_template_id :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#

require 'spec_helper'

describe Endpoint do

  expect_it { to ensure_inclusion_of(:endpoint_type).in_array(%w(ws rest webapp)) }

  it 'should set proper default values' do
    expect(subject.endpoint_type).to eql 'ws'
  end

  expect_it { to belong_to :port_mapping_template }
  expect_it { to validate_presence_of :port_mapping_template }

end
