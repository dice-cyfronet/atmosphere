require 'spec_helper'

describe ApplianceType do

  subject { FactoryGirl.create(:appliance_type) }

  expect_it { to be_valid }

  expect_it { to belong_to :security_proxy }

  expect_it { to validate_presence_of :name }
  expect_it { to validate_presence_of :visibility }

  expect_it { to validate_uniqueness_of :name }

  expect_it { to ensure_inclusion_of(:visibility).in_array(%w(under_development unpublished published)) }
  # TODO this cannot be used due to https://github.com/thoughtbot/shoulda-matchers/issues/291
  # Uncomment when available
  #expect_it { to ensure_inclusion_of(:shared).in_array([true, false]) }
  #expect_it { to ensure_inclusion_of(:scalable).in_array([true, false]) }

  expect_it { to have_db_index(:name).unique(true) }

  it 'should set proper default values' do
    expect(subject.visibility).to eql 'under_development'
    expect(subject.shared).to eql false
    expect(subject.scalable).to eql false
  end

end
