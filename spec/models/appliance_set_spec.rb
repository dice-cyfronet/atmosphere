# == Schema Information
#
# Table name: appliance_sets
#
#  id                 :integer          not null, primary key
#  context_id         :string(255)      not null
#  priority           :integer          default(50), not null
#  appliance_set_type :string(255)      default("development"), not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe ApplianceSet do

  subject { FactoryGirl.create(:appliance_set) }

  it { should be_valid }

  #it { should validate_presence_of :name }
  it { should validate_presence_of :context_id }
  it { should validate_presence_of :priority }
  it { should validate_presence_of :appliance_set_type }
  it { should validate_presence_of :user_id }

  it { should validate_uniqueness_of :context_id }

  it { should validate_numericality_of :priority }
  it { should ensure_inclusion_of(:priority).in_range(1..100) }

  it { should ensure_inclusion_of(:appliance_set_type).in_array(%w(development workflow portal)) }

  it { should have_readonly_attribute :appliance_set_type }
  it { should have_readonly_attribute :context_id }

  it { should have_db_index(:context_id).unique(true) }
  it { should have_db_index :user_id }

  it 'should set proper default values' do
    subject.priority.should == 50
    subject.appliance_set_type.should eql 'development'
  end

  it { should belong_to :user }
  it { should validate_presence_of :user }


  pending 'should allow for many VirtualMachines'
  #  it { should have_many :virtual_machines }

  pending 'should be at most 1 development appliance set in the scope of specific User'
  #  .scoped_to(:user_id) should help here

end
