module Atmosphere
  class VmTagsCreatorWorker
    include Sidekiq::Worker

    sidekiq_options queue: :cloud
    sidekiq_options retry: 4

    sidekiq_retries_exhausted do |msg|
      Raven.capture_message(
        "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}."\
        ' Manual intervention required!',
        level: :error,
        tags: { type: 'vm_tagging' }
      )
    end

    def perform(vm_id, tags_map)
      vm = VirtualMachine.find_by(id: vm_id)

      tag(vm, tags_map) if vm
    end

    private

    def tag(vm, tags_map)
      t = vm.tenant
      if ['openstack', 'rackspace'].include?(t.technology)
        tag_vm_on_openstack(vm, t.cloud_client, tags_map)
      else
        tag_vm(vm.id_at_site, t.cloud_client, tags_map)
      end
    end

    def tag_vm_on_openstack(vm, cloud_client, tags_map)
      if vm.state == 'active'
        tag_vm(vm.id_at_site, cloud_client, tags_map)
      else
        VmTagsCreatorWorker.perform_in(2.minutes, vm.id, tags_map)
      end
    end

    def tag_vm(server_id, cloud_client, tags_map)
      Rails.logger.debug { "Creating tags #{tags_map} for server #{server_id}" }
      begin
        cloud_client.create_tags_for_vm(server_id, tags_map)
      rescue Fog::Compute::AWS::NotFound, Fog::Compute::OpenStack::NotFound => e
        Raven.capture_message(
          "Failed to annotate #{server_id} because of #{e.message}"\
          ' - will try to retry',
          level: :warning,
          tags: { type: 'vm_tagging' }
        )
        raise e
      end
      Rails.logger.debug { "Successfuly created tags for server #{server_id}" }
    end
  end
end