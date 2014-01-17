class VmUpdater
  def initialize(site, server)
    @site = site
    @server = server
  end

  def update
    vm.source_template = source_template
    vm.name = server.name || '[unnamed]'
    vm.state = map_state(server.state.downcase.to_sym)
    update_ips if update_ips?

    unless vm.save
      error("unable to create/update #{vm.id} virtual machine because: #{vm.errors.to_json}")
    end

    vm
  end

  private

  attr_reader :site, :server

  # AWS states: pending , running, shuttingdown, stopped, stopping, terminated
  # OS states: active build deleted error hard_reboot password reboot rebuild rescue resize revert_resize shutoff suspended unknown verify_resize
  def map_state(key)
    {pending: :build , running: :active, shuttingdown: :deleted, stopped: :deleted, stopping: :deleted, terminated: :deleted, active: :active, build: :build, deleted: :deleted, error: :error, hard_reboot: :hard_reboot, password: :password, reboot: :reboot, rebuild: :rebuild, rescue: :rescue, resize: :resize, revert_resize: :revert_resize, shutoff: :shutoff, suspended: :suspended, unknown: :unknown, verify_resize: :verify_resize}[key]
  end

  def vm
    @vm ||= site.virtual_machines.find_or_initialize_by(id_at_site: server.id)
  end

  def source_template
    VirtualMachineTemplate.find_by(compute_site: site, id_at_site: server.image_id)
  end

  def update_ips?
    [:active, 'active', :error, 'error'].include? vm.state
  end

  def update_ips
    vm.ip = server.addresses['private'].first['addr'] if server.addresses and !server.addresses.blank?
  end

  def error(message)
    Rails.logger.error "MONITORING: #{message}"
  end
end