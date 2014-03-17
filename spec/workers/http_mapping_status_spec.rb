require 'spec_helper'

describe HttpMappingMonitoringWorker do

  include ApiHelpers

  let(:hm) { create(:http_mapping) }

  it 'should set status for OK' do

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::NEW)

    url_check = double()
    url_check.stub(:is_available) { true }

    HttpMappingMonitoringWorker.new(url_check).perform(maping.id)

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::OK)

  end
end