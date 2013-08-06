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

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable,
  # :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable, :recoverable,
         :validatable, :token_authenticatable

  validates :login, uniqueness: { case_sensitive: false }

  # Devise method overridden to allow sing in with email or login
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(login) = :value OR lower(email) = :value", { value: login.downcase }]).first
    else
      where(conditions).first
    end
  end
end
