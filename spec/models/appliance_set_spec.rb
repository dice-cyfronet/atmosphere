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

  expect_it { to be_valid }

  expect_it { to validate_presence_of :context_id }
  expect_it { to validate_presence_of :priority }
  expect_it { to validate_presence_of :appliance_set_type }
  expect_it { to validate_presence_of :user_id }

  expect_it { to validate_uniqueness_of :context_id }

  expect_it { to validate_numericality_of :priority }
  expect_it { to ensure_inclusion_of(:priority).in_range(1..100) }

  expect_it { to ensure_inclusion_of(:appliance_set_type).in_array(%w(development workflow portal)) }

  expect_it { to have_readonly_attribute :appliance_set_type }
  expect_it { to have_readonly_attribute :context_id }

  expect_it { to have_db_index(:context_id).unique(true) }
  expect_it { to have_db_index :user_id }

  it 'should set proper default values' do
    expect(subject.priority).to eq 50
    expect(subject.appliance_set_type).to eql 'development'
  end

  expect_it { to belong_to :user }
  expect_it { to validate_presence_of :user }


  pending 'should allow many Appliances'
  #  expect_it { to have_many :appliances }

  pending 'to be at most 1 development appliance set in the scope of specific User'
  #  ??? expect_it { to validate_uniqueness_of(:appliance_set_type).scoped_to(:user_id) }

end
