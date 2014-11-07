require 'rails_helper'

describe Atmosphere::EndpointStatusCheckWorker do

  include ApiHelpers

  let(:url_check) { double() }
  let(:hm) { create(:http_mapping, monitoring_status: :pending); }
  let(:hm_ok) { create(:http_mapping, monitoring_status: :ok); }

  it 'should set status from pending to ok' do
    allow(url_check).to receive(:is_available)
      .with(hm.url).and_return(true)

    hm_before = Atmosphere::HttpMapping.find_by id: hm.id
    expect(hm_before.monitoring_status.pending?).to be_truthy

    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = Atmosphere::HttpMapping.find_by id: hm_before.id
    expect(hm_after.monitoring_status.ok?).to be_truthy
  end

  it 'should set status from ok to lost' do
    allow(url_check).to receive(:is_available)
      .with(hm_ok.url).and_return(false)

    hm_before = Atmosphere::HttpMapping.find_by id: hm_ok.id
    expect(hm_before.monitoring_status.ok?).to be_truthy

    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = Atmosphere::HttpMapping.find_by id: hm_before.id
    expect(hm_after.monitoring_status.lost?).to be_truthy
  end

  it 'should leave pending' do
    allow(url_check).to receive(:is_available)
          .with(hm.url).and_return(false)

    hm_before = Atmosphere::HttpMapping.find_by id: hm.id
    expect(hm_before.monitoring_status.pending?).to be_truthy

    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform(hm_before.id)

    hm_after = Atmosphere::HttpMapping.find_by id: hm_before.id
    expect(hm_after.monitoring_status.pending?).to be_truthy
  end

  it 'does nothing, when mapping not found in db' do
    expect(url_check).to_not receive(:is_available)
    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform('nonexisting')
  end
end