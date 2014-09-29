module Atmosphere
  class Monitoring::ZabbixClient
    def initialize
      # smart hack :-)
      # requiring zabbix fails if there is no zabbix section in air.yml. In 2_app.rb it is checked whether this section is present and this service is instantiated only if the section exists.
      require 'zabbix'
    end

    def register_host(uuid, ip)
      Zabbix.register_host(uuid, ip)
    end

    def unregister_host(monitoring_id)
      Zabbix.unregister_host(monitoring_id)
    end

    def host_metrics(monitoring_id)
      Zabbix.host_metrics(monitoring_id)
    end
  end
end