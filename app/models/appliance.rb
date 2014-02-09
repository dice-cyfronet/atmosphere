# == Schema Information
#
# Table name: appliances
#
#  id                                  :integer          not null, primary key
#  appliance_set_id                    :integer          not null
#  appliance_type_id                   :integer          not null
#  user_key_id                         :integer
#  appliance_configuration_instance_id :integer          not null
#  state                               :string(255)      default("new"), not null
#  name                                :string(255)
#  created_at                          :datetime
#  updated_at                          :datetime
#

class Appliance < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_set
  belongs_to :appliance_type
  belongs_to :appliance_configuration_instance
  belongs_to :user_key

  belongs_to :fund

  before_destroy :final_billing

  validates_presence_of :appliance_set, :appliance_type, :appliance_configuration_instance

  enumerize :state, in: [:new, :satisfied, :unsatisfied], predicates: true
  validates_presence_of :state
  enumerize :billing_state, in: [:prepaid, :expired, :error], predicates: true
  validates_presence_of :billing_state

  validates_numericality_of :amount_billed

  has_many :http_mappings, dependent: :destroy
  has_many :virtual_machines, through: :deployments, dependent: :destroy
  has_many :deployments

  has_one :dev_mode_property_set, dependent: :destroy, autosave: true
  attr_readonly :dev_mode_property_set

  before_create :create_dev_mode_property_set, if: :development?
  before_save :assign_default_fund
  after_destroy :remove_appliance_configuration_instance_if_needed
  after_destroy :optimize_destroyed_appliance
  after_create :initial_billing, :optimize_saved_appliance

  scope :started_on_site, ->(compute_site) { joins(:virtual_machines).where(virtual_machines: {compute_site: compute_site}) }

  def to_s
    "#{id} #{appliance_type.name} with configuration #{appliance_configuration_instance_id}"
  end

  def development?
    appliance_set.appliance_set_type.development?
  end

  private

  def assign_default_fund
    # This is a "goalkeeper" method which will assign this appliance to its owner's default fund, if no fund has been specified yet.
    # It is provided to ensure compatibility with old APIs of Atmosphere which do not request funds to be specified when instantiating appliances
    # Once the APIs have been updated, this method will be deprecated and should be removed.
    if self.fund.blank?
      self.fund = self.appliance_set.user.default_fund
      # Note that id the user does not have a default fund assigned, this method will be unable to figure out any useful fund for this appliance.
    end
  end

  def final_billing
    # Perform one final billing action for this appliance prior to its destruction.
    BillingService::bill_appliance(self, Time.now, "Final billing action prior to appliance destruction.",false)
  end

  def create_dev_mode_property_set
    self.dev_mode_property_set = DevModePropertySet.create_from(appliance_type) unless self.dev_mode_property_set
  end

  def remove_appliance_configuration_instance_if_needed
    if appliance_configuration_instance.appliances.blank?
      Air.action_logger.info "         -- appliance configuration intance #{appliance_configuration_instance.id} destroyed by appliance #{id}"
      appliance_configuration_instance.destroy
    end
  end

  def optimize_saved_appliance
    Optimizer.instance.run(created_appliance: self)
  end

  def initial_billing
    # This method bills the freshly saved appliance for the first time.
    # Note: This will fail if the appliance does not have a fund assigned (which is a 'should never happen' error. :)
    BillingService::bill_appliance(self, Time.now, "Initial billing action following appliance instantiation.", true)
    # CAUTION: This may immediately render the appliance "expired" if the assigned fund does not provide sufficient resources to pay for the appliance.
    # In such cases, the appliance should never be visualized in platform GUIs or returned to external clients as 'active'.
  end

  def optimize_destroyed_appliance
    Optimizer.instance.run(destroyed_appliance: self)
  end

end
