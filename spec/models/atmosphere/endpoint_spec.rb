# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  description              :text
#  descriptor               :text
#  endpoint_type            :string(255)      default("ws"), not null
#  invocation_path          :string(255)      not null
#  port_mapping_template_id :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#  secured                  :boolean          default(FALSE), not null
#

require 'rails_helper'

describe Atmosphere::Endpoint do

  it { should validate_inclusion_of(:endpoint_type).in_array(%w(ws rest webapp)) }

  it 'should set proper default values' do
    expect(subject.endpoint_type).to eql 'ws'
  end

  it { should belong_to :port_mapping_template }
  it { should validate_presence_of :port_mapping_template }
  it { should validate_presence_of :invocation_path }
  it { should validate_presence_of :name }

  describe '#invocation_path' do
    context 'with spaces at the beginning and at the end' do
      subject { create(:endpoint, invocation_path: ' with spaces ') }

      it 'removes spaces on save' do
        expect(subject.invocation_path).to eq 'with spaces'
      end
    end
  end
end
