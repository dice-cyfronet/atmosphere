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
module Atmosphere
  class User < ActiveRecord::Base
    include Atmosphere::UserExt

    # Include default devise modules. Others available are:
    # :confirmable,
    # :registerable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable,
           :rememberable, :trackable, :recoverable,
           :validatable, :omniauthable

    validates :login, uniqueness: { case_sensitive: false }

    include Atmosphere::LoginAndEmail
    include Atmosphere::Nondeletable

    has_many :appliance_sets,
             dependent: :destroy,
             class_name: 'Atmosphere::ApplianceSet'

    has_many :user_keys,
             dependent: :destroy,
             class_name: 'Atmosphere::UserKey'

    has_many :appliance_types,
             class_name: 'Atmosphere::ApplianceType'

    has_many :funds,
             through: :user_funds,
             class_name: 'Atmosphere::Fund'

    has_many :user_funds,
             dependent: :destroy,
             class_name: 'Atmosphere::UserFund'

    has_many :billing_logs,
             dependent: :nullify,
             class_name: 'Atmosphere::BillingLog'

    after_create :check_fund_assignment

    scope :with_vm, ->(vm) do
      joins(appliance_sets: { appliances: :virtual_machines }).
        where(atmosphere_virtual_machines: { id: vm.id })
    end

    include Gravtastic
    gravtastic default: 'mm'

    # roles
    include RoleModel
    roles :admin, :developer

    def default_fund
      # Return this user's default fund, if it exists.
      dfs = user_funds.where(default: true)
      dfs.blank? ? nil : dfs.first.fund
    end

    def generate_password
      self.password = self.password_confirmation =
        Devise.friendly_token.first(8)
    end

    def to_s
      "#{login} <#{email}>"
    end

    def descriptive_name
      "#{full_name} (#{login}) <#{email}>"
    end

    def admin?
      has_role? :admin
    end

    def developer?
      has_role? :developer
    end

    def clew_roles
      roles.map { |r| r == :admin ? 'cloudadmin' : r.to_s }
    end

    # Returns a list of this user's tenants to which the user is linked via
    # fund assignments
    def tenants
      Atmosphere::Tenant.joins(funds: :users).
        where(atmosphere_users: { id: id })
    end

    def tenant_ids
      tenants.pluck(&:id)
    end

    private

    # Checks whether any fund has been assigned to this user.
    # If not, assign the first available fund (if it exists) and make it this
    # user's default fund.
    # This method is provided to ensure compatibility with old versions of
    # Atmosphere which do not supply fund information when creating users.
    # Once the platform APIs are updated, this method will be deprecated and
    # should be removed.
    def check_fund_assignment
      if Atmosphere::UserFund.where(user: self).blank? &&
         Atmosphere::Fund.all.count > 0
        user_funds << Atmosphere::UserFund.new(user: self,
                                               fund: Atmosphere::Fund.first,
                                               default: true)
      end
    end
  end
end
