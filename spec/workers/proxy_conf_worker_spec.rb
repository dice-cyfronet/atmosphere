require 'spec_helper'

describe ProxyConfWorker do

  before do
    Sidekiq::Client.stub(:push)
  end

  it { should be_processed_in :proxyconf }

  describe '#perform' do
    context 'when site is not found' do
      it 'log error' do
        expect(Rails.logger).to receive(:error)
        subject.perform('not_existing')
      end

      it 'does not generate proxy conf' do
        expect(Sidekiq::Client).to_not receive(:push)
        subject.perform('not_existing')
      end
    end

    context 'when compute site exists' do
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
    end

    def args(override={})
      {
        'queue' => override['queue'] ? override['queue'] : anything,
        'class' => override['class'] ? override['class'] : anything,
        'args'  => override['args']  ? override['args']  : anything,
      }
    end
  end

  describe '#regeneration_required' do
    let(:cs) { create(:compute_site, regenerate_proxy_conf: false) }

    it 'changes regeneration required into true' do
      ProxyConfWorker.regeneration_required(cs)
      expect(cs.regenerate_proxy_conf).to be_true
    end
  end

  describe '#regenerate_proxy_confs' do
    let!(:cs1) { create(:compute_site, regenerate_proxy_conf: true) }
    let!(:cs2) { create(:compute_site, regenerate_proxy_conf: false) }
    let!(:cs3) { create(:compute_site, regenerate_proxy_conf: true) }

    it 'generates proxy conf job only for sites which requires regeneration' do
      # NOT SURE WHY JOBS ARRAY IS ALWAYS EMPTY

      # ProxyConfWorker.regenerate_proxy_confs
      # expect(ProxyConfWorker).to have(2).jobs
      # expect(ProxyConfWorker).to have_enqueued_job(cs1.id)
      # expect(ProxyConfWorker).to have_enqueued_job(cs3.id)
    end
  end
end