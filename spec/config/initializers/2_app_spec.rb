require 'rails_helper'

describe Air do
  before { Air.clear_cache! }

  context 'cloud client cache' do
    it 'returns cached client if valid' do
      site_id, client = register_cloud_cient

      expect(Air.get_cloud_client(site_id)).to eq client
    end

    it 'returns nil when cached cloud client is outdated' do
      site_id, client = register_cloud_cient
      time_travel(8.hours)

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

  context 'metrics store' do
    it 'returns null client when no configuration' do
      Air.config['influxdb'] = nil

      expect(Air.metrics_store)
        .to be_an_instance_of Monitoring::NullMetricsStore
    end

    it 'returns real client when configuration available' do
      create_influxdb_config!

      expect(Air.metrics_store)
        .to be_an_instance_of Monitoring::InfluxdbMetricsStore
    end

    it 'creates new client when client outdated' do
      create_influxdb_config!
      client = Air.metrics_store
      time_travel(1.hour)

      expect(Air.metrics_store).not_to eq client
    end

    def create_influxdb_config!
      Air.config['influxdb'] = Settingslogic.new({})
      Air.config.influxdb['host'] = 'influxdb.host.edu.pl'
      Air.config.influxdb['username'] = 'influxdbuser'
      Air.config.influxdb['password'] = 'influxdbpassword'
      Air.config.influxdb['database'] = 'influxdbdatabase'
    end
  end

  def time_travel(interval)
    allow(Time).to receive(:now).and_return(Time.now + interval)
  end
end