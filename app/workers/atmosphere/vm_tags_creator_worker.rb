module Atmosphere
  class VmTagsCreatorWorker
    include Sidekiq::Worker

    sidekiq_options queue: :tags
    sidekiq_options retry: 4

    sidekiq_retries_exhausted do |msg|
      capture_message(
        "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}. Manual intervention required!",
        level: :error
      )
    end

    def perform(vm_id, tags_map)
      vm = VirtualMachine.find(vm_id)
      cs = vm.compute_site
      if cs.technology == 'openstack'
        tag_vm_on_openstack(vm, cs.cloud_client, tags_map)
      else
        tag_vm_on_amazon(vm, cs.cloud_client, tags_map)
      end
    end

    def capture_message(msg, options = {})
      Raven.capture_message(
        msg,
        level: options[:level] || :warning,
        tags: {
          type: 'vm_tagging'
        }
      )
    end

    private
    def tag_vm_on_openstack(vm, cloud_client, tags_map)
      if vm.state == 'active'
        tag_vm(vm.id_at_site, cloud_client, tags_map)
      else
        VmTagsCreatorWorker.perform_in(2.minutes, vm.id, tags_map)
      end
    end

    def tag_vm_on_amazon(vm, cloud_client, tags_map)
      tag_vm(vm.id_at_site, cloud_client, tags_map)
    end

    def tag_vm(server_id, cloud_client, tags_map)
      Rails.logger.debug { "Creating tags #{tags_map} for server #{server_id}" }
      begin
        cloud_client.create_tags_for_vm(server_id, tags_map)
      rescue Fog::Compute::AWS::NotFound, Fog::Compute::OpenStack::NotFound => e
        capture_message("Failed to annotate #{server_id} because of #{e.message}- will try to retry")
        raise e
      end
      Rails.logger.debug { "Successfuly created tags for server #{server_id}" }
    end
  end
end