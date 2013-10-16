# == Schema Information
#
# Table name: user_keys
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  fingerprint :string(255)      not null
#  public_key  :text             not null
#  user_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe UserKey do

  before do
    Fog.mock!
    create(:compute_site, technology: 'aws', config: '{"provider": "aws", "aws_access_key_id": "bzdura",  "aws_secret_access_key": "bzdura",  "region": "eu-west-1"}')
  end

  subject { create(:user_key) }
  expect_it { to be_valid }
  [:name, :public_key, :user].each do |attr|
    expect_it { to validate_presence_of attr}
  end
  expect_it { to validate_uniqueness_of(:name).scoped_to(:user_id) }
  it 'should calculate fingerprint' do
    expect(subject.fingerprint).to eql '43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a'
  end
  expect_it { to belong_to :user }

  it 'should import key to cloud site' do
    ComputeSite.all.each do |cs|
      keypair = cs.cloud_client.describe_key_pairs.body['keySet'].select{|k|
        puts k
        k['keyName'] == subject.name
      }
      puts "K#{keypair}"
      puts "S#{subject.name}"
      expect(keypair['keyName']).to eq(subject.name)
      expect(keypair['keyFingerPrint']).to eq(subject.fingerprint)
    end
  end
end
