class VmUpdater
  def initialize(site, server)
    @site = site
    @server = server
  end

  def update
    vm.source_template = source_template
    vm.name = server.name
    vm.state = server.state.downcase.to_sym
    update_ips if update_ips?

    unless vm.save
      error("unable to create/update #{vm.id} virtual machine because: #{vm.errors.to_json}")
    end

    vm
  end

  private

  attr_reader :site, :server

  def vm
    @vm ||= site.virtual_machines.find_or_initialize_by(id_at_site: server.id)
  end

  def source_template
    VirtualMachineTemplate.find_by(compute_site: site, id_at_site: server.image_id)
  end

  def update_ips?
    vm.state == :active || vm.state == :error
  end

  def update_ips
    vm.ip = server.addresses['private'].first['addr'] if server.addresses
  end

  def error(message)
    Rails.logger.error "MONITORING: #{message}"
  end
end