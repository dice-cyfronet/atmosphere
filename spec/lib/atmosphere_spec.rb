require 'rails_helper'
require 'atmosphere'

describe Atmosphere do
  include TimeHelper

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
      Atmosphere.monitoring_client = nil

      expect(Atmosphere.monitoring_client)
        .to be_an_instance_of Atmosphere::Monitoring::NullClient
    end

    it 'returns real client when configuration available' do
      Atmosphere.monitoring_client = 'other_client'

      expect(Atmosphere.monitoring_client).to eq 'other_client'
    end
  end

  context 'metrics store' do
    it 'returns null client when no configuration' do
      Atmosphere.metrics_store = nil

      expect(Atmosphere.metrics_store)
        .to be_an_instance_of Atmosphere::Monitoring::NullMetricsStore
    end

    it 'returns real client when configuration available' do
      Atmosphere.metrics_store = 'other_client'

      expect(Atmosphere.metrics_store).to eq 'other_client'
    end
  end
end