require 'spec_helper'

describe UserKey do
  subject { create(:user_key) }
  expect_it { to be_valid }
  [:name, :fingerprint, :public_key].each do |attr|
    expect_it { to validate_presence_of attr}
  end
  expect_it { to validate_uniqueness_of(:name).scoped_to(:user_id) }
  it 'should calculate fingerprint' do
    expect(subject.fingerprint).to eql '43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a'
  end
  expect_it { to belong_to :user }

  pending 'shoud check if key and fingerprint are readonly'
end
