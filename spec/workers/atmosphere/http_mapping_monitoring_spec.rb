require 'rails_helper'

describe HttpMappingMonitoringWorker do
  include ApiHelpers

  let(:status_check) { double }
  subject { HttpMappingMonitoringWorker.new(status_check) }

  it 'should check pending' do
    hm_pending = create(:http_mapping)

    expect(status_check).to receive(:submit).with(hm_pending.id)

    subject.perform(:pending)
  end

  it 'should check ok' do
    hm_ok = create(:http_mapping, monitoring_status: :ok)

    expect(status_check).to receive(:submit).with(hm_ok.id)

    subject.perform(:ok)
  end
end
