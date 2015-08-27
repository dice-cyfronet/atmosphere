module Atmosphere
  class Appliance < ActiveRecord::Base
    include Atmosphere::ApplianceExt
    extend Enumerize
    serialize :optimization_policy_params

    belongs_to :appliance_set,
               class_name: 'Atmosphere::ApplianceSet'

    belongs_to :appliance_type,
               class_name: 'Atmosphere::ApplianceType'

    belongs_to :appliance_configuration_instance,
               class_name: 'Atmosphere::ApplianceConfigurationInstance'

    belongs_to :user_key,
               class_name: 'Atmosphere::UserKey'

    belongs_to :fund,
               class_name: 'Atmosphere::Fund'

    has_many :http_mappings,
             dependent: :destroy,
             autosave: true,
             class_name: 'Atmosphere::HttpMapping'

    has_many :virtual_machines,
             through: :deployments,
             class_name: 'Atmosphere::VirtualMachine'

    has_many :deployments,
             dependent: :destroy,
             class_name: 'Atmosphere::Deployment'

    has_many :tenants,
             through: :appliance_tenants,
             class_name: 'Atmosphere::Tenant'

    has_many :appliance_tenants,
             dependent: :destroy,
             class_name: 'Atmosphere::ApplianceTenant'

    has_many :actions,
             dependent: :destroy,
             class_name: 'Atmosphere::Action'

    has_one :dev_mode_property_set,
            dependent: :destroy,
            autosave: true,
            class_name: 'Atmosphere::DevModePropertySet'

    validates :appliance_set, presence: true
    validates :appliance_type, presence: true
    validates :appliance_configuration_instance, presence: true
    validates :state, presence: true
    validates :amount_billed, numericality: true

    enumerize :state, in: [:new, :satisfied, :unsatisfied], predicates: true

    attr_readonly :dev_mode_property_set

    before_create :create_dev_mode_property_set, if: :development?
    after_destroy :remove_appliance_configuration_instance_if_needed

    scope :started_on_site, ->(tenant) do
      joins(:virtual_machines).
        where(atmosphere_virtual_machines: { tenant: tenant })
    end

    def to_s
      "#{id} #{appliance_type.name} with configuration \
       #{appliance_configuration_instance_id}"
    end

    def development?
      appliance_set.appliance_set_type.development?
    end

    def create_dev_mode_property_set(options={})
      unless dev_mode_property_set
        set = DevModePropertySet.create_from(appliance_type)
        set.preference_memory = options[:preference_memory] if options[:preference_memory]
        set.preference_cpu = options[:preference_cpu] if options[:preference_cpu]
        set.preference_disk = options[:preference_disk] if options[:preference_disk]
        set.os_family = appliance_type.os_family
        Rails.logger.info("Created DMPS with OS family #{set.os_family}")
        self.dev_mode_property_set = set
        set.appliance = self
      end
    end

    def active_vms
      virtual_machines.active
    end

    def user_data
      appliance_configuration_instance.payload
    end

    def optimization_strategy
      strategy_name =
        begin
          optimization_policy || appliance_set.optimization_policy || 'default'
        rescue NameError
          'default'
        end
      strategy_class = ('Atmosphere::OptimizationStrategy::' +
                        strategy_name.to_s.capitalize!).constantize
      strategy_class.new(self)
    end

    def owned_by?(user)
      appliance_set.user_id == user.id
    end

    def prepaid_until
      # Helper method which determines how long this appliance
      # will remain prepaid
      if deployments.blank?
        # Invoking this method on an appl whith 0 deployments is a nasal demons
        # scenario: the question doesn't make sense and neither will the answer.
        # Returning fixed time is least likely to break the client.
        Time.parse('2000-01-01 12:00')
      else
        deployments.max_by(&:prepaid_until).prepaid_until
      end
    end

    # This method provided for backward compatibility
    def billing_state
      if deployments.any? { |d| d.billing_state == 'prepaid' }
        'prepaid'
      else
        'expired'
      end
    end

    private

    # TODO: This could be buggy. Make sure to verify that Atmosphere uses
    # the correct fund to spawn VMs in the selected tenant.
    def assign_fund
      funds = Fund.joins(tenants: :virtual_machine_templates).
              where(id: appliance_set.user.funds,
                    atmosphere_virtual_machine_templates: {
                      appliance_type_id: appliance_type.id
                    })

      if tenants.present?
        # we need to use map here, because this code can be invoked
        # before first appliance save. Then appliance does not have id
        # assigned which is required to perform tenants query with appliance
        # join.
        funds = funds.where(atmosphere_tenants: { id: tenants.map(&:id) })
      end

      self.fund = if funds.include? default_fund
                    default_fund
                  else
                    funds.blank? ? default_fund : funds.first
                  end
    end

    def default_fund
      if appliance_set && appliance_set.user
        appliance_set.user.default_fund
      end
    end

    def remove_appliance_configuration_instance_if_needed
      if appliance_configuration_instance &&
         appliance_configuration_instance.appliances.blank?
        appliance_configuration_instance.destroy
      end
    end
  end
end
