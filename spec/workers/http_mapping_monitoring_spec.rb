require 'spec_helper'

describe HttpMappingMonitoringWorker do

  include ApiHelpers

  let(:url_check) { double() }
  let(:scheduler) { double() }
  let(:hm) { create(:http_mapping) }

  it 'should change status from NEW to OK' do

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::NEW)

    url_check.stub(:is_available) { true }
    scheduler.stub(:schedule) do |mapping, serial_no|
      expect(mapping.id).to eq hm.id
    end

    HttpMappingMonitoringWorker.new(url_check).perform(maping.id)

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::OK)

  end

  it 'should change status from NEW to PENDING' do

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::NEW)

    url_check.stub(:is_available) { false }
    scheduler.stub(:schedule) do |mapping, serial_no|
      expect(mapping.id).to eq hm.id
    end

    HttpMappingMonitoringWorker.new(url_check).perform(maping.id)

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::PENDING)

  end

  it 'should change status from OK to LOST' do

    maping = HttpMapping.find_by id: hm.id

    maping.monitoring_status = HttpMappingStatus::OK
    maping.save

    expect(maping.monitoring_status).to eq(HttpMappingStatus::OK)

    url_check.stub(:is_available) { false }
    scheduler.stub(:schedule) do |mapping, serial_no|
      expect(mapping.id).to eq hm.id
    end

    HttpMappingMonitoringWorker.new(url_check, scheduler).perform(maping.id)

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::LOST)

  end

  it 'should not perform monitoring' do

    maping = HttpMapping.find_by id: hm.id

    maping.monitoring_status = HttpMappingStatus::NOT_MONITORED
    maping.save

    expect(maping.monitoring_status).to eq(HttpMappingStatus::NOT_MONITORED)

    HttpMappingMonitoringWorker.new(url_check, scheduler).perform(maping.id)

    maping = HttpMapping.find_by id: hm.id

    expect(maping.monitoring_status).to eq(HttpMappingStatus::NOT_MONITORED)

  end


end