require 'spec_helper'

describe HttpMappingMonitoringWorker do

  include ApiHelpers

  let(:url_check) { double() }
  let(:scheduler) { double() }
  let(:hm_pending) { create(:http_mapping) }
  let(:hm_ok) { create(:http_mapping, :monitoring_status => :ok) }

  it 'should check pending' do

    status_check = double()
    status_check.stub(:submit){ |arg|
      expect(arg).to eq(hm_pending.id)
    }

    hm_pending.save
    hm_ok.save

    HttpMappingMonitoringWorker.new(status_check).perform(:pending)

  end

  it 'should check ok' do

    status_check = double()
    status_check.stub(:submit){ |arg|
      expect(arg).to eq(hm_ok.id)
    }

    hm_pending.save
    hm_ok.save

    HttpMappingMonitoringWorker.new(status_check).perform(:ok)

  end


end