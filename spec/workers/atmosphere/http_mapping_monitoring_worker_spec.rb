require 'spec_helper'

describe Atmosphere::HttpMappingMonitoringWorker do
  include ApiHelpers

  let(:status_check) { double() }
  let(:hm_pending) { create(:http_mapping) }
  let(:hm_ok) { create(:http_mapping, monitoring_status: :ok) }

  subject { Atmosphere::HttpMappingMonitoringWorker.new(status_check) }

  it 'should check pending' do
    expect(status_check).to receive(:submit).with(hm_pending.id)

    subject.perform(:pending)
  end

  it 'should check ok' do
    expect(status_check).to receive(:submit).with(hm_ok.id)

    subject.perform(:ok)
  end
end