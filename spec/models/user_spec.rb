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

require 'spec_helper'
require Rails.root.join("spec/shared_examples/token_authenticatable.rb")

describe User do
  expect_it { to have_many(:appliance_sets).dependent(:destroy) }
  expect_it { to have_many(:user_keys).dependent(:destroy) }
  expect_it { to have_many :appliance_types }
  expect_it { to have_and_belong_to_many :security_proxies }
  expect_it { to have_and_belong_to_many :security_policies }

  it_behaves_like 'token_authenticatable'

  describe '#generate_password' do
    before { subject.generate_password }

    it 'generates new random password' do
      expect(subject.changed?).to be_true
      expect(subject.password).to eq subject.password_confirmation
    end
  end

  describe '#vph_find_or_create' do
    let!(:user1) { create(:user, login: 'user1') }
    let!(:user2) { create(:user, email: 'user2@foobar.pl') }

    context 'with existing user' do
      let(:user1_auth) do
        OmniAuth::AuthHash.new({info:
          {
            login: user1.login,
            email: 'updated_email@foobar.pl',
            full_name: 'Updated full name',
            roles: ['admin']
          }
        })
      end

      let(:user2_auth) do
        OmniAuth::AuthHash.new({info:
          {
            login: 'new_login',
            email: user2.email,
            full_name: 'Updated full name',
            roles: ['developer']
          }
        })
      end

      it 'should be found using login' do
        found = User.vph_find_or_create(user1_auth)
        expect(found.id).to eq user1.id
      end

      it 'should be found using email' do
        found = User.vph_find_or_create(user2_auth)
        expect(found.id).to eq user2.id
      end

      it 'should update user details' do
        found = User.vph_find_or_create(user1_auth)
        expect(found.email).to eq user1_auth.info.email
        expect(found.full_name).to eq user1_auth.info.full_name
        expect(found.roles.to_a).to eq [:admin]
      end

      it 'should update also user login' do
        found = User.vph_find_or_create(user2_auth)
        expect(found.login).to eq user2_auth.info.login
      end
    end

    context 'new user' do
      let(:new_user_auth) do
        OmniAuth::AuthHash.new({info:
          {
            login: 'new_user',
            email: 'new_user@email.pl',
            full_name: 'full name',
            roles: ['admin', 'developer']
          }
        })
      end

      it 'should create new user' do
        expect {
          User.vph_find_or_create(new_user_auth)
        }.to change { User.count }.by(1)
      end

      it 'should set user details' do
        user = User.vph_find_or_create(new_user_auth)

        expect(user.login).to eq new_user_auth.info.login
        expect(user.email).to eq new_user_auth.info.email
        expect(user.full_name).to eq new_user_auth.info.full_name
        expect(user.roles.to_a).to eq [:admin, :developer]
      end
    end
  end
end
