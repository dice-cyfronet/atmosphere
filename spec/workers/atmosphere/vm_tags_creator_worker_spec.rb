require 'spec_helper'

describe Atmosphere::VmTagsCreatorWorker do

  vm_id = 1
  id_at_site = 'ID_AT_SITE'
  tags_map = {'1_tag_name' => '1_value', '2_tag_name' => '2_value'}

  let(:cloud_client_mock) {double('cloud client')}
  let(:cs_mock) { double('compute site') }
  let(:vm_mock) { double('virtual machine')}

  before do
    allow(cs_mock).to receive(:cloud_client).and_return cloud_client_mock
    allow(Atmosphere::VirtualMachine).
      to receive(:find_by).with(id: vm_id).and_return(vm_mock)
    allow(vm_mock).to receive(:id).and_return vm_id
    allow(vm_mock).to receive(:id_at_site).and_return id_at_site
    allow(vm_mock).to receive(:compute_site).and_return cs_mock
  end

  context 'active vm' do
    before do
      allow(vm_mock).to receive(:state).and_return('active')
    end
    context 'on openstack' do
      before do
        allow(cs_mock).to receive(:technology).and_return('openstack')
      end

      it 'calls cloud client with appropriate tag parameters' do
        expect(cloud_client_mock).to receive(:create_tags_for_vm).with(vm_mock.id_at_site, tags_map)
        expect(Raven).not_to receive(:capture_exception)
        Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
      end

      it 'reraise exception' do
        exc = Fog::Compute::OpenStack::NotFound.new
        expect(cloud_client_mock).to receive(:create_tags_for_vm).with(vm_mock.id_at_site, tags_map).and_raise(exc)
        expect {
          Atmosphere::VmTagsCreatorWorker.new
            .perform(vm_mock.id, tags_map)
        }.to raise_error(Fog::Compute::OpenStack::NotFound)
      end

    end

    context 'on amazon' do
      before do
        allow(cs_mock).to receive(:technology).and_return('aws')
      end

      it 'calls cloud client with appropriate tag parameters' do
        expect(cloud_client_mock).to receive(:create_tags_for_vm).with(vm_mock.id_at_site, tags_map)
        expect(Raven).not_to receive(:capture_exception)
        Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
      end

      it 'reports error to Raven' do
        exc = Fog::Compute::AWS::NotFound.new
        expect(cloud_client_mock).to receive(:create_tags_for_vm).with(vm_mock.id_at_site, tags_map).and_raise(exc)
        expect(Raven).to receive(:capture_message).with(start_with('Failed to annotate'), anything)
        begin
          Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
        rescue
          # exc is expected to be raised
        end
      end

    end
  end

  it 'do nothing when VM was already deleted', focus: true do
    allow(Atmosphere::VirtualMachine).
      to receive(:find_by).
      with(id: 'non_existing').
      and_return(nil)

    expect do
      Atmosphere::VmTagsCreatorWorker.new.
        perform('non_existing', tags_map)
    end.to_not raise_error
  end

  context 'inactive vm' do

    before do
      allow(vm_mock).to receive(:state).and_return('build')
    end

    context 'on openstack' do

      before do
        allow(cs_mock).to receive(:technology).and_return('openstack')
      end

      it 'does not call cloud client' do
        expect(cloud_client_mock).not_to receive(:create_tags_for_vm)
        expect(Raven).not_to receive(:capture_exception)
        Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
      end

      it 'reschedules tag creation' do
        expect(Atmosphere::VmTagsCreatorWorker)
          .to receive(:perform_in)
            .with(2.minutes, vm_mock.id, tags_map)

        Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
      end

    end

    context 'on amazon' do
      before do
        allow(cs_mock).to receive(:technology).and_return('aws')
      end

      it 'calls cloud client with appropriate tag parameters' do
        expect(cloud_client_mock).to receive(:create_tags_for_vm).with(vm_mock.id_at_site, tags_map)
        expect(Raven).not_to receive(:capture_exception)
        Atmosphere::VmTagsCreatorWorker.new.perform(vm_mock.id, tags_map)
      end
    end
  end

  it 'report raven issue when retries exhausted' do
    Atmosphere::VmTagsCreatorWorker.within_sidekiq_retries_exhausted_block do
      expect(Raven).to receive(:capture_message)
    end
  end
end
