# == Schema Information
#
# Table name: virtual_machines
#
#  id                          :integer          not null, primary key
#  id_at_site                  :string(255)      not null
#  name                        :string(255)      not null
#  state                       :string(255)      not null
#  ip                          :string(255)
#  managed_by_atmosphere       :boolean          default(FALSE), not null
#  compute_site_id             :integer          not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  virtual_machine_template_id :integer
#  virtual_machine_flavor_id   :integer
#  monitoring_id               :integer
#

module Atmosphere
  class VirtualMachine < ActiveRecord::Base
    extend Enumerize
    include Childhoodable

    ALLOWED_STATES = [
      'active', 'build', 'deleted', 'error', 'hard_reboot',
      'password', 'reboot', 'rebuild', 'rescue', 'resize',
      'revert_resize', 'shutoff', 'suspended', 'unknown',
      'verify_resize', 'saving', 'paused'
    ]

    has_many :saved_templates,
      dependent: :nullify,
      class_name: 'Atmosphere::VirtualMachineTemplate'

    has_many :port_mappings,
      dependent: :delete_all,
      class_name: 'Atmosphere::PortMapping'

    belongs_to :source_template,
      class_name: 'Atmosphere::VirtualMachineTemplate',
      foreign_key: 'virtual_machine_template_id'

    belongs_to :compute_site,
      class_name: 'Atmosphere::ComputeSite'

    belongs_to :virtual_machine_flavor,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    has_many :appliances,
      through: :deployments,
      dependent: :destroy,
      class_name: 'Atmosphere::Appliance'

    has_many :deployments,
      dependent: :destroy,
      class_name: 'Atmosphere::Deployment'

    validates :name,
              presence: true

    validates :id_at_site,
              uniqueness: { scope: :compute_site_id }

    validates :state, inclusion: ALLOWED_STATES

    enumerize :state, in: ALLOWED_STATES

    before_update :update_in_monitoring, if: :ip_changed?
    before_destroy :unregister_from_monitoring, if: :in_monitoring?
    before_destroy :cant_destroy_non_managed_vm
    after_update :regenerate_dnat, if: :ip_changed?
    after_destroy :delete_dnat, if: :ip?

    scope :manageable, -> { where(managed_by_atmosphere: true) }
    scope :active, -> { where("state = 'active' AND ip IS NOT NULL") }

    scope :reusable_by, ->(appliance) do
      manageable.joins(:appliances).where(
        atmosphere_appliances: {
          appliance_configuration_instance_id:
            appliance.appliance_configuration_instance_id
        },
        compute_site: appliance.compute_sites
      )
    end

    scope :unused, -> do
      manageable.where(%{id NOT IN (SELECT DISTINCT(virtual_machine_id)
                            FROM atmosphere_deployments)
                        AND id NOT IN (SELECT DISTINCT(virtual_machine_id)
                            FROM atmosphere_virtual_machine_templates WHERE
                              virtual_machine_id IS NOT NULL)})
    end

    def uuid
      "#{compute_site.site_id}-vm-#{id_at_site}"
    end

    def reboot
      cloud_action(:reboot, :reboot)
    end

    def stop
      cloud_action(:stop, :shutoff)
    end

    def pause
      cloud_action(:pause, :paused)
    end

    def suspend
      cloud_action(:suspend, :suspended)
    end

    def start
      cloud_action(:start, :active)
    end

    def appliance_type
      return appliances.first.appliance_type if appliances.first
      return nil
    end

    def destroy(delete_in_cloud = true)
      saved_templates.each {|t| return if t.state == 'saving'}
      perform_delete_in_cloud if delete_in_cloud && managed_by_atmosphere
      super()
    end

    # Deletes all dnat redirections and then adds. Use it when IP of the vm has changed and existing redirection would not work any way.
    def regenerate_dnat
      if ip_was
        if delete_dnat(ip_was)
          port_mappings.delete_all
        end
      end
      add_dnat if ip
    end

    def add_dnat
      return unless ip?
      pmts = nil
      if (appliances.first and appliances.first.development?)
        pmts = appliances.first.dev_mode_property_set.port_mapping_templates
      else
        pmts = appliance_type.port_mapping_templates if appliance_type
      end
      return unless pmts
      already_added_mapping_tmpls = port_mappings ? port_mappings.collect {|m| m.port_mapping_template} : []
      to_add = pmts.select {|pmt| pmt.application_protocol.none?} - already_added_mapping_tmpls
      compute_site.dnat_client.add_dnat_for_vm(self, to_add).each {|added_mapping_attrs| PortMapping.create(added_mapping_attrs)}
    end

    def delete_dnat(ip = self.ip)
      compute_site.dnat_client.remove(ip)
    end

    def update_in_monitoring
      return unless managed_by_atmosphere?
      logger.info "Updating vm #{uuid} in monitoring"
      if ip_was && monitoring_id
        unregister_from_monitoring
      end
      register_in_monitoring if ip
    end

    def register_in_monitoring
      logger.info "Registering vm #{uuid} in monitoring"
      self[:monitoring_id] = monitoring_client.register_host(uuid, ip)
    end

    def unregister_from_monitoring
      logger.info "Unregistering vm #{uuid} with monitoring host id #{monitoring_id} from monitoring"
      monitoring_client.unregister_host(self.monitoring_id)
      self[:monitoring_id] = nil
    end

    def current_load_metrics
      if monitoring_id
        metrics = monitoring_client.host_metrics(monitoring_id)
        metrics.collect_last if metrics
      else
        nil
      end
    end

    def save_load_metrics(metrics)
      return unless metrics
      cpu_load_1 = 'Processor load (1 min average per core)'
      cpu_load_5 = 'Processor load (5 min average per core)'
      cpu_load_15 = 'Processor load (15 min average per core)'

      total_mem = 'Total memory'
      available_mem = 'Available memory'

      metrics_hash = {}
      metrics.each {|m| metrics_hash.merge!(m)}

      metrics_store = Atmosphere.metrics_store
      appliances.each do |appl|
        metrics_store.write_point('cpu_load_1', {appliance_set_id:appl.appliance_set_id, appliance_id: appl.id, virtual_machine_id: uuid, value: metrics_hash[cpu_load_1]})
        metrics_store.write_point('cpu_load_5', {appliance_set_id:appl.appliance_set_id, appliance_id: appl.id, virtual_machine_id: uuid, value: metrics_hash[cpu_load_5]})
        metrics_store.write_point('cpu_load_15', {appliance_set_id:appl.appliance_set_id, appliance_id: appl.id, virtual_machine_id: uuid, value: metrics_hash[cpu_load_15]})
        if metrics_hash[total_mem] && metrics_hash[total_mem] > 0 && metrics_hash[available_mem] && metrics_hash[available_mem] > 0
          mem_usage = (metrics_hash[total_mem] - metrics_hash[available_mem]) / metrics_hash[total_mem]
          metrics_store.write_point('memory_usage', {appliance_set_id:appl.appliance_set_id, appliance_id: appl.id, virtual_machine_id: uuid, value: mem_usage})
        end
      end
    end

    private

    def in_monitoring?
      ip? && monitoring_id?
    end

    def perform_delete_in_cloud
      unless cloud_client.servers.destroy(id_at_site)
        Raven.capture_message(
          "Error destroying VM in cloud",
          {
            logger: 'error',
            extra: {
              id_at_site: id_at_site,
              compute_site_id: compute_site_id
            }
          }
        )
      end
    rescue Fog::Compute::OpenStack::NotFound, Fog::Compute::AWS::NotFound
      logger.warn("VM with #{id_at_site} does not exist - continuing")
    end

    def cant_destroy_non_managed_vm
      errors.add :base, 'Virtual Machine is not managed by atmosphere' unless managed_by_atmosphere
    end

    def monitoring_client
      Atmosphere.monitoring_client
    end

    def cloud_action(aciton_name, sucess_state)
      action_status = cloud_server.send(aciton_name)
      change_state_on_success(action_status, sucess_state)
    end

    def cloud_server
      cloud_client.servers.get(id_at_site)
    end

    def cloud_client
      @cloud_client ||= compute_site.cloud_client
    end

    def change_state_on_success(success, new_state)
      if success
        self.state = new_state
        save
      else
        false
      end
    end
  end
end
