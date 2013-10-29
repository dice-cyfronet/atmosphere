require 'spec_helper'

describe ProxyConfWorker do

  before do
    Sidekiq::Client.stub(:push)
  end

  describe '#perform' do
    it 'log error when compute site is not found' do
      expect(Rails.logger).to receive(:error)
      subject.perform('not_existing')
    end

    it 'does not generate proxy conf when compute site is not found' do
      expect(Sidekiq::Client).to_not receive(:push)
      subject.perform('not_existing')
    end

    let(:cs) { create(:compute_site) }
    let(:generator) { double }

    it 'sends job for site with proxies' do
      expect(Sidekiq::Client).to receive(:push)
      subject.perform(cs)
    end

    it 'sends job into propert compute site queue' do
      expect(Sidekiq::Client).to receive(:push).with(args('queue' => cs.site_id))
      subject.perform(cs)
    end

    it 'sends job into redirus worker' do
      expect(Sidekiq::Client).to receive(:push).with(args('class' => Redirus::Worker::Proxy))
      subject.perform(cs)
    end

    it 'sends proxy conf and site properties' do
      expect(SiteProxyConf).to receive(:new).with(cs).and_return(generator)
      expect(generator).to receive(:generate).and_return('proxyconf')
      expect(generator).to receive(:properties).and_return('properties')
      expect(Sidekiq::Client).to receive(:push).with(args('args' => ['proxyconf', 'properties']))
      subject.perform(cs)
    end

    def args(override={})
      {
        'queue' => override['queue'] ? override['queue'] : anything,
        'class' => override['class'] ? override['class'] : anything,
        'args'  => override['args']  ? override['args']  : anything,
      }
    end
  end
end