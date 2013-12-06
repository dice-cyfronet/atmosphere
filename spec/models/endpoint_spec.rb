# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  description              :text
#  descriptor               :text
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
  expect_it { to validate_presence_of :invocation_path }
  expect_it { to validate_presence_of :name }

  describe '#invocation_path' do
    context 'with spaces at the beginning and at the end' do
      subject { create(:endpoint, invocation_path: ' with spaces ') }

      it 'removes spaces on save' do
        expect(subject.invocation_path).to eq 'with spaces'
      end
    end
  end
end
