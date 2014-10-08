# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  login                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  authentication_token   :string(255)
#  email                  :string(255)      default(""), not null
#  full_name              :string(255)
#  roles_mask             :integer
#  created_at             :datetime
#  updated_at             :datetime
#

require 'rails_helper'
require_relative "../../shared_examples/token_authenticatable.rb"

describe Atmosphere::User do
  subject { build(:user) }

  it { should have_many(:appliance_sets).dependent(:destroy) }
  it { should have_many(:user_keys).dependent(:destroy) }
  it { should have_many :appliance_types }

  it_behaves_like 'token_authenticatable'

  describe '#generate_password' do
    before { subject.generate_password }

    it 'generates new random password' do
      expect(subject.changed?).to be_truthy
      expect(subject.password).to eq subject.password_confirmation
    end
  end
end
