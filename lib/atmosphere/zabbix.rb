require_relative "zabbix/metrics.rb"
require_relative "zabbix/registration.rb"

module Atmosphere
  module Zabbix

    @metrics = Metrics.new
    @registration = Registration.new
    @mock = false

    def host_metrics(hostid)
      return nil if @mock
      @metrics.create_host_metrics(hostid)
    end

    def register_host(unique_id, ip, port = nil)
      return 1 if @mock
      @registration.register(unique_id, ip, port)
    end

    def unregister_host(hostid)
      return if @mock
      @registration.unregister(hostid)
    end

    def mock!
      @mock = true
    end

    module_function :host_metrics, :register_host, :unregister_host, :mock!
  end
end
