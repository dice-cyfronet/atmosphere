# == Schema Information
#
# Table name: appliance_sets
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  context_id    :string(255)      not null
#  priority      :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe ApplianceSet do

  subject { ApplianceSet.create(name:'N', context_id: 'C') }  # This DOES work
  #subject { FactoryGirl.build(:appliance_set) }  # This DOESN'T work and hell if I know why

  it { should be_valid }

  #it { should validate_presence_of :name }
  it { should validate_presence_of :context_id }
  it { should validate_presence_of :priority }
  it { should validate_presence_of :appliance_set_type }

  it { should validate_uniqueness_of :context_id }

  it { should validate_numericality_of :priority }
  it { should ensure_inclusion_of(:priority).in_range(1..100) }

  it { should ensure_inclusion_of(:appliance_set_type).in_array(%w(development workflow portal)) }

  it { should have_readonly_attribute :appliance_set_type }
  it { should have_readonly_attribute :context_id }

  it { should have_db_index(:context_id).unique(true) }

  it 'should set proper default values' do
    subject.priority.should == 50
    subject.appliance_set_type.should eql 'development'
  end

  pending 'should allow for many VirtualMachines'
  #  should have_many :virtual_machines
  pending 'should belong to exactly one User'
  #  should belong_to ? :user
  pending 'should be at most 1 development appliance set in the scope of specific User'
  #  .scoped_to(:user_id) should help here

end
