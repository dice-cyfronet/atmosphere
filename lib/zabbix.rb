require_relative "zabbix/metrics.rb"
require_relative "zabbix/registration.rb"

module Zabbix

  @metrics = Metrics.new
  @registration = Registration.new

  def host_metrics(hostid)
    @metrics.create_host_metrics(hostid)
  end

  def register_host(unique_id, ip, port)
    @registration.register(unique_id, ip, port)
  end

  def unregister_host(hostid)
    @registration.unregister(hostid)
  end

  module_function :host_metrics, :register_host, :unregister_host

end

