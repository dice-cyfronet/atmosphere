# == Schema Information
#
# Table name: appliance_sets
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  priority           :integer          default(50), not null
#  appliance_set_type :string(255)      default("workflow"), not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#

require 'rails_helper'

describe Atmosphere::ApplianceSet do

  subject { create(:appliance_set) }

  it { should be_valid }

  it { should validate_presence_of :priority }
  it { should validate_presence_of :appliance_set_type }
  it { should validate_presence_of :user }

  it { should validate_numericality_of :priority }
  it { should ensure_inclusion_of(:priority).in_range(1..100) }

  it { should ensure_inclusion_of(:appliance_set_type).in_array(%w(development workflow portal)) }
  it { should have_readonly_attribute :appliance_set_type }

  pending 'to be at most 1 development appliance set in the scope of specific User'
  # TODO the below does not work as expected, something more is needed
  #context 'if appliance_set_type is either development or portal' do
  #  before { subject.stub(:appliance_set_type) { 'development' } }
  #  it { should validate_uniqueness_of(:appliance_set_type).scoped_to(:user_id) }
  #end

  it { should have_db_index :user_id }

  it 'should set proper default values' do
    expect(subject.priority).to eq 50
    expect(subject.appliance_set_type).to eql 'workflow'
  end

  it { should belong_to :user }
  it { should validate_presence_of :user }
  it { should have_many(:appliances).dependent(:destroy) }

end
