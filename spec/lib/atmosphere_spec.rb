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

  context 'nic provider' do
    class DummyNicProvider
      def initialize(_config = nil); end

      def get(_appl, _tmpl)
        nil
      end
    end

    context 'when compute site does not define provider class name' do
      let(:cs) { create(:compute_site) }
      it 'returns NullNicProvider' do
        expect(Atmosphere.nic_provider(cs).class).
          to eq Atmosphere::NicProvider::NullNicProvider
      end
    end

    context 'when compute site defines provider class name' do
      let(:c_name) { 'DummyNicProvider' }
      let(:cs) { create(:compute_site, nic_provider_class_name: c_name) }

      it 'returns provider of appropriate class' do
        expect(Atmosphere.nic_provider(cs).class).to eq DummyNicProvider
      end

      it 'creates provider with compute site specific configuration' do
        PROVIDER_CONF = 'Nic provider configuration'
        cs.nic_provider_config = PROVIDER_CONF
        expect(DummyNicProvider).to receive(:new).with PROVIDER_CONF
        Atmosphere.nic_provider(cs)
      end
    end
  end
end
