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
end