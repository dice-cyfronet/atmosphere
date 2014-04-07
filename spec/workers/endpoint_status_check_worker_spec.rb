require 'spec_helper'

describe EndpointStatusCheckWorker do

  include ApiHelpers

  let(:url_check) { double() }
  let(:hm) { create(:http_mapping, :monitoring_status => :pending); }
  let(:hm_ok) { create(:http_mapping, :monitoring_status => :ok); }

  it 'should set status from pending to ok' do

    url_check.stub(:is_available) do |url|
      expect(url).to eq(hm.url)
      true
    end

    hm_before = HttpMapping.find_by :id => hm.id
    expect(hm_before.monitoring_status.pending?).to be true

    EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = HttpMapping.find_by :id => hm_before.id
    expect(hm_after.monitoring_status.ok?).to be true
  end

  it 'should set status from ok to lost' do

    url_check.stub(:is_available) do |url|
      expect(url).to eq(hm_ok.url)
      false
    end

    hm_before = HttpMapping.find_by :id => hm_ok.id
    expect(hm_before.monitoring_status.ok?).to be true

    EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = HttpMapping.find_by :id => hm_before.id
    expect(hm_after.monitoring_status.lost?).to be true
  end

  it 'should leave pending' do

    url_check.stub(:is_available) do |url|
      expect(url).to eq(hm.url)
      false
    end

    hm_before = HttpMapping.find_by :id => hm.id
    expect(hm_before.monitoring_status.pending?).to be true

    EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = HttpMapping.find_by :id => hm_before.id
    expect(hm_after.monitoring_status.pending?).to be true
  end

  it 'does nothing, when mapping not found in db' do
    expect(url_check).to_not receive(:is_available)
    EndpointStatusCheckWorker.new(url_check).perform('nonexisting')
  end
end