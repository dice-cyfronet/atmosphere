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
#  fund_id                             :integer
#  last_billing                        :datetime
#  state_explanation                   :string(255)
#

class Appliance < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance_set
  belongs_to :appliance_type
  belongs_to :appliance_configuration_instance
  belongs_to :user_key

  belongs_to :fund

  validates_presence_of :appliance_set, :appliance_type, :appliance_configuration_instance

  enumerize :state, in: [:new, :satisfied, :unsatisfied], predicates: true
  validates_presence_of :state

  has_many :http_mappings, dependent: :destroy, autosave: true
  has_many :virtual_machines, through: :deployments, dependent: :destroy
  has_many :deployments

  has_one :dev_mode_property_set, dependent: :destroy, autosave: true
  attr_readonly :dev_mode_property_set

  before_create :create_dev_mode_property_set, if: :development?
  after_destroy :remove_appliance_configuration_instance_if_needed
  after_destroy :optimize_destroyed_appliance
  after_create :optimize_saved_appliance

  scope :started_on_site, ->(compute_site) { joins(:virtual_machines).where(virtual_machines: {compute_site: compute_site}) }

  def to_s
    "#{id} #{appliance_type.name} with configuration #{appliance_configuration_instance_id}"
  end

  def development?
    appliance_set.appliance_set_type.development?
  end

  def create_dev_mode_property_set(options={})
    unless self.dev_mode_property_set
      set = DevModePropertySet.create_from(appliance_type)
      set.preference_memory = options[:preference_memory] if options[:preference_memory]
      set.preference_cpu = options[:preference_cpu] if options[:preference_cpu]
      set.preference_disk = options[:preference_disk] if options[:preference_disk]
      self.dev_mode_property_set = set
      set.appliance = self
    end
  end

  def active_vms
    virtual_machines.active
  end

  private

  def remove_appliance_configuration_instance_if_needed
    if appliance_configuration_instance && appliance_configuration_instance.appliances.blank?
      appliance_configuration_instance.destroy
    end
  end

  def optimize_saved_appliance
    Optimizer.instance.run(created_appliance: self)
  end

  def optimize_destroyed_appliance
    Optimizer.instance.run(destroyed_appliance: self)
  end

end
