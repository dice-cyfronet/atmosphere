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
    self.table_name = 'users'

    # Include default devise modules. Others available are:
    # :confirmable,
    # :registerable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable,
           :rememberable, :trackable, :recoverable,
           :validatable, :omniauthable

    attr_accessor :mi_ticket

    validates :login, uniqueness: { case_sensitive: false }

    include Atmosphere::LoginAndEmail
    include Atmosphere::TokenAuthenticatable
    include Atmosphere::Nondeletable

    has_many :appliance_sets,
      dependent: :destroy,
      class_name: 'Atmosphere::ApplianceSet'

    has_many :user_keys,
      dependent: :destroy,
      class_name: 'Atmosphere::UserKey'

    has_many :appliance_types,
      class_name: 'Atmosphere::ApplianceType'

    has_and_belongs_to_many :security_proxies,
      class_name: 'Atmosphere::SecurityProxy'

    has_and_belongs_to_many :security_policies,
      class_name: 'Atmosphere::SecurityPolicy'

    has_many :funds,
      through: :user_funds,
      class_name: 'Atmosphere::Fund'

    has_many :user_funds,
      dependent: :destroy,
      class_name: 'Atmosphere::UserFund'

    has_many :billing_logs,
      dependent: :nullify,
      class_name: 'Atmosphere::BillingLog'

    before_save :check_fund_assignment
    around_update :manage_metadata

    scope :with_vm, ->(vm) do
      joins(appliance_sets: { appliances: :virtual_machines })
        .where(virtual_machines: {id: vm.id})
    end

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
      dfs.blank? ? nil : dfs.first.fund
    end

    def generate_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end

    def to_s
      "#{login} <#{email}>"
    end

    def admin?
      has_role? :admin
    end

    def developer?
      has_role? :developer
    end

    private

    # Checks whether any fund has been assigned to this user.
    # If not, assign the first available fund (if it exists) and make it this user's default fund
    # This method is provided to ensure compatibility with old versions of Atmosphere which do not supply fund information when creating users.
    # Once the platform APIs are updated, this method will be deprecated and should be removed.
    def check_fund_assignment
      if funds.blank? and Atmosphere::Fund.all.count > 0
        user_funds << Atmosphere::UserFund.new(user: self, fund: Atmosphere::Fund.first, default: true)
      end
    end

    # METADATA lifecycle methods

    # Check if we need to update metadata regarding this user's ATs, if so, perform the task
    def manage_metadata
      login_changed = login_changed?
      yield
      update_appliance_type_metadata if login_changed
    end

    def update_appliance_type_metadata
      appliance_types.select(&:publishable?).each(&:update_metadata)
    end

  end
end
