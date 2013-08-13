# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  login                :string(255)      default(""), not null
#  encrypted_password   :string(255)      default(""), not null
#  remember_created_at  :datetime
#  sign_in_count        :integer          default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  authentication_token :string(255)
#  email                :string(255)      default(""), not null
#  full_name            :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe User do

  subject { FactoryGirl.create(:user) }

  it { should be_valid }

  it { should have_many :appliance_sets }

  pending 'add better specs here'

end
