require 'spec_helper'

describe HttpMappingMonitoringWorker do

  include ApiHelpers

  let(:status_check) { double() }
  let(:hm_pending) { create(:http_mapping); hm_pending.save }
  let(:hm_ok) { create(:http_mapping, :monitoring_status => :ok); hm_ok.save}

  it 'should check pending' do

    status_check.stub(:submit){ |id| expect(id).to eq(hm_pending.id) }

    HttpMappingMonitoringWorker.new(status_check).perform(:pending)

  end

  it 'should check ok' do

    status_check.stub(:submit){ |id| expect(id).to eq(hm_ok.id) }

    HttpMappingMonitoringWorker.new(status_check).perform(:ok)

  end


end