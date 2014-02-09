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

class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable,
  # :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :rememberable, :trackable, :recoverable,
         :validatable, :omniauthable

  validates :login, uniqueness: { case_sensitive: false }

  include LoginAndEmail
  include TokenAuthenticatable
  include Nondeletable

  has_many :appliance_sets, dependent: :destroy
  has_many :user_keys, dependent: :destroy
  has_many :appliance_types

  has_and_belongs_to_many :security_proxies
  has_and_belongs_to_many :security_policies

  has_many :funds, through: :user_funds
  has_many :user_funds, dependent: :destroy
  has_many :billing_logs, dependent: :nullify

  include Gravtastic
  gravtastic default: 'mm'

  #roles
  include RoleModel
  roles :admin, :developer

  def self.vph_find_or_create(auth)
    user = User.where(login: auth.info.login).first || User.where(email: auth.info.email).first
    unless user
      user = User.new
      user.generate_password
    end

    user.login     = auth.info.login
    user.email     = auth.info.email
    user.full_name = auth.info.full_name
    user.roles     = auth.info.roles
    user.save

    user
  end

  def default_fund
    # Return this user's default fund, if it exists.
    dfs = self.user_funds.where(default: true)
    dfs.blank? ? nil : dfs.first
  end

  def generate_password
    self.password = self.password_confirmation = Devise.friendly_token.first(8)
  end

  def to_s
    "#{login} <#{email}>"
  end

end
