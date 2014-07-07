require 'rails_helper'

describe Air do
  context 'cloud client cache' do
    it 'returns cached client if valid' do
      site_id, client = register_cloud_cient

      expect(Air.get_cloud_client(site_id)).to eq client
    end

    it 'returns nil when cachec cloud client is outdated' do
      site_id, client = register_cloud_cient
      allow(Time).to receive(:now).and_return(Time.now + 8.hours)

      expect(Air.get_cloud_client(site_id)).to be_nil
    end

    def register_cloud_cient
      client = 'cloud_cilent'
      site_id = 'cloud_site_id'
      Air.register_cloud_client(site_id, client)

      [ site_id, client ]
    end
  end

  context 'monitoring client' do
    it 'returns null client when no configuration' do
      Air.config['zabbix'] = nil

      expect(Air.monitoring_client)
        .to be_an_instance_of Monitoring::NullClient
    end

    it 'returns real client when configuration available' do
      Air.config['zabbix'] = Settingslogic.new({})
      Air.config.zabbix['url'] = 'https://host'
      Air.config.zabbix['user'] = 'zabbix_user'
      Air.config.zabbix['password'] = 'zabbix_pass'
      Air.config.zabbix['atmo_template_name'] = 'Template OS Linux'
      Air.config.zabbix['atmo_group_name'] = 'Atmosphere Internal Monitoring'
      Air.config.zabbix['zabbix_agent_port'] = 10050
      Air.config.zabbix['query_interval'] = 5

      expect(Air.monitoring_client)
        .to be_an_instance_of Monitoring::ZabbixClient
    end
  end
end