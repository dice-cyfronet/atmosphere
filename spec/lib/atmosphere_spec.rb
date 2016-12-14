require 'rails_helper'
require 'atmosphere'

describe Atmosphere do
  include TimeHelper

  before { Atmosphere.clear_cache! }

  context 'cloud client cache' do
    it 'returns cached client if valid' do
      tenant_id, client = register_cloud_cient

      expect(Atmosphere.get_cloud_client(tenant_id)).to eq client
    end

    it 'returns nil when cached cloud client is outdated' do
      tenant_id, client = register_cloud_cient
      time_travel(8.hours)

      expect(Atmosphere.get_cloud_client(tenant_id)).to be_nil
    end

    def register_cloud_cient
      client = 'cloud_cilent'
      tenant_id = 'tenant_id'
      Atmosphere.register_cloud_client(tenant_id, client)

      [ tenant_id, client ]
    end
  end

  context 'nic provider' do
    class DummyNicProvider
      def initialize(_config = nil); end

      def get(_appl, _tmpl)
        nil
      end
    end

    context 'when tenant does not define provider class name' do
      let(:t) { create(:tenant) }
      it 'returns NullNicProvider' do
        expect(Atmosphere.nic_provider(t).class).
          to eq Atmosphere::NicProvider::DefaultNicProvider
      end
    end

    context 'when tenant defines provider class name' do
      let(:c_name) { 'DummyNicProvider' }
      let(:t) { create(:tenant, nic_provider_class_name: c_name) }

      it 'returns provider of appropriate class' do
        expect(Atmosphere.nic_provider(t).class).to eq DummyNicProvider
      end

      it 'creates provider of appropriate class if config is empty' do
        t.nic_provider_config = ''
        expect(DummyNicProvider).to receive(:new).with({tenant: t})
        Atmosphere.nic_provider(t)
      end

      it 'creates provider of appropriate class if config is empty' do
        t.nic_provider_config = nil
        expect(DummyNicProvider).to receive(:new).with({tenant: t})
        Atmosphere.nic_provider(t)
      end

      it 'creates provider with tenant specific configuration' do
        t.nic_provider_config = '{"key": "val"}'
        expect(DummyNicProvider).to receive(:new).with(key: 'val')
        Atmosphere.nic_provider(t)
      end
    end
  end
end
