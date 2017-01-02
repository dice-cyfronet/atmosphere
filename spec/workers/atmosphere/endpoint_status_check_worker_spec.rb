require 'rails_helper'

describe Atmosphere::EndpointStatusCheckWorker do
  include ApiHelpers

  let(:url_check) { double }
  let(:hm) { create(:http_mapping, monitoring_status: :pending); }
  let(:hm_ok) { create(:http_mapping, monitoring_status: :ok); }

  it 'should set status from pending to ok' do
    url_check_response(true)

    check_and_reload(hm)

    expect(hm.monitoring_status).to be_ok
  end

  it 'should set status from ok to lost' do
    url_check_response(false)

    check_and_reload(hm_ok)

    expect(hm_ok.monitoring_status).to be_lost
  end

  it 'should leave pending' do
    url_check_response(false)

    check_and_reload(hm)

    expect(hm.monitoring_status).to be_pending
  end

  it 'does nothing, when mapping not found in db' do
    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform('nonexisting')
  end

  def check_and_reload(mapping)
    Atmosphere::EndpointStatusCheckWorker.new(url_check).perform(mapping.id)
    mapping.reload
  end

  def url_check_response(response_state)
    allow(url_check).to receive(:available?).
      with(hm_ok.url, Atmosphere.url_monitoring.timeout).
      and_return(response_state)
  end
end
