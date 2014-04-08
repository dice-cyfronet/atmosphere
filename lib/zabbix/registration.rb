require_relative "client.rb"

module Zabbix
  class Registration

    def initialize(client = nil, group_name = nil, template_name = nil)
      @group_name = group_name || Air.config.zabbix.atmo_group_name
      @template_name = template_name || Air.config.zabbix.atmo_template_name
      @zabbix_agent_port = Air.config.zabbix.zabbix_agent_port
      @client = client
    end

    def register(unique_id, ip, port = nil)

      port = port || @zabbix_agent_port

      # Interface type
      # 1 - agent
      # 2 - SNMP
      # 3 - IPMI
      # 4 - JMX
      type = 1

      # Can be empty if the connection is made via IP
      dns = ''

      # Whether the interface is used as default on the hos
      main = 1

      # Whether the connection should be made via IP
      useip = 1

      # Request ids
      groupid = client.api.hostgroups.get_id(:name => @group_name)
      templateid = client.api.templates.get_id(:host => @template_name)

      # TODO create_or_update method is more suitable in this place but for some reason it does not update old values (eg. ip)
      begin
        host_id = client.api.hosts.create(
            :host => unique_id,
            :interfaces => [
                {
                    :type => type,
                    :ip => ip,
                    :port => port,
                    :useip => useip,
                    :main => main,
                    :dns => dns
                }
            ],
            :groups => [ :groupid => groupid],
            :templates => [ :templateid => templateid]
        )

        host_id
      rescue
        nil
      end
    end

    def unregister(host_id)
      begin
        client.api.hosts.delete host_id
      rescue
        Rails.logger.error "Error while removing host #{host_id} from Zabbix"
      end
    end

    def client
      @client ||= Client.new
    end

  end
end
