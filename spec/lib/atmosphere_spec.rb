require 'rails_helper'
require 'atmosphere'

describe Atmosphere do
  before { Atmosphere.clear_cache! }

  context 'cloud client cache' do
    it 'returns cached client if valid' do
      site_id, client = register_cloud_cient

      expect(Atmosphere.get_cloud_client(site_id)).to eq client
    end

    it 'returns nil when cached cloud client is outdated' do
      site_id, client = register_cloud_cient
      time_travel(8.hours)

      expect(Atmosphere.get_cloud_client(site_id)).to be_nil
    end

    def register_cloud_cient
      client = 'cloud_cilent'
      site_id = 'cloud_site_id'
      Atmosphere.register_cloud_client(site_id, client)

      [ site_id, client ]
    end
  end

  context 'monitoring client' do
    it 'returns null client when no configuration' do
      Atmosphere.config['zabbix'] = nil

      expect(Atmosphere.monitoring_client)
        .to be_an_instance_of Atmosphere::Monitoring::NullClient
    end

    it 'returns real client when configuration available' do
      Atmosphere.config['zabbix'] = Settingslogic.new({})
      Atmosphere.config.zabbix['url'] = 'https://host'
      Atmosphere.config.zabbix['user'] = 'zabbix_user'
      Atmosphere.config.zabbix['password'] = 'zabbix_pass'
      Atmosphere.config.zabbix['atmo_template_name'] = 'Template OS Linux'
      Atmosphere.config.zabbix['atmo_group_name'] = 'Atmosphere Internal Monitoring'
      Atmosphere.config.zabbix['zabbix_agent_port'] = 10050
      Atmosphere.config.zabbix['query_interval'] = 5

      expect(Atmosphere.monitoring_client)
        .to be_an_instance_of Atmosphere::Monitoring::ZabbixClient
    end
  end

  context 'metrics store' do
    it 'returns null client when no configuration' do
      Atmosphere.config['influxdb'] = nil

      expect(Atmosphere.metrics_store)
        .to be_an_instance_of Atmosphere::Monitoring::NullMetricsStore
    end

    it 'returns real client when configuration available' do
      create_influxdb_config!

      expect(Atmosphere.metrics_store)
        .to be_an_instance_of Atmosphere::Monitoring::InfluxdbMetricsStore
    end

    it 'creates new client when client outdated' do
      create_influxdb_config!
      client = Atmosphere.metrics_store
      time_travel(1.hour)

      expect(Atmosphere.metrics_store).not_to eq client
    end

    def create_influxdb_config!
      Atmosphere.config['influxdb'] = Settingslogic.new({})
      Atmosphere.config.influxdb['host'] = 'influxdb.host.edu.pl'
      Atmosphere.config.influxdb['username'] = 'influxdbuser'
      Atmosphere.config.influxdb['password'] = 'influxdbpassword'
      Atmosphere.config.influxdb['database'] = 'influxdbdatabase'
    end
  end

  def time_travel(interval)
    allow(Time).to receive(:now).and_return(Time.now + interval)
  end
end