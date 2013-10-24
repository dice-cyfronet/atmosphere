require 'spec_helper'

describe WranglerRegistrarWorker do

  context 'as a sidekiq worker' do
    it 'responds to #perform' do
      expect(subject).to respond_to(:perform)
    end
  end

  it 'calls remote wrangler service' do
    pending
  end

end