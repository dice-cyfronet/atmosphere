require 'spec_helper'

describe VmTagsCreatorWorker do

  server_id = 'SERVER_ID'
  site_id = 1
  tags_map = {'1_tag_name' => '1_value', '2_tag_name' => '2_value'}

  let(:cs_mock) {double('compute site')}
  let(:cloud_client_mock) {double('cloud client')}

  it 'calls cloud client with appropriate tag parameters' do
    expect(ComputeSite).to receive(:find).with(site_id).and_return cs_mock
    expect(cs_mock).to receive(:cloud_client).and_return cloud_client_mock
    expect(cloud_client_mock).to receive(:create_tags_for_vm).with(server_id, tags_map)
    expect(Raven).not_to receive(:capture_exception)
    VmTagsCreatorWorker.new.perform(server_id, site_id, tags_map)
  end

  it 'handles tag creation errors' do
    expect(ComputeSite).to receive(:find).with(site_id).and_return cs_mock
    expect(cs_mock).to receive(:cloud_client).and_return cloud_client_mock
    exc = Fog::Compute::AWS::NotFound.new
    expect(cloud_client_mock).to receive(:create_tags_for_vm).with(server_id, tags_map).and_raise(exc)
    VmTagsCreatorWorker.new.perform(server_id, site_id, tags_map)
  end

  it 'reports error to Raven' do
    expect(ComputeSite).to receive(:find).with(site_id).and_return cs_mock
    expect(cs_mock).to receive(:cloud_client).and_return cloud_client_mock
    exc = Fog::Compute::AWS::NotFound.new
    expect(cloud_client_mock).to receive(:create_tags_for_vm).with(server_id, tags_map).and_raise(exc)
    expect(Raven).to receive(:capture_exception).with(exc)
    VmTagsCreatorWorker.new.perform(server_id, site_id, tags_map)
  end

end