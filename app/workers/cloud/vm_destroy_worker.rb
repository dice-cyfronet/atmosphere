module Cloud
  class VmDestroyWorker
    include Sidekiq::Worker

    sidekiq_options queue: :cloud
    sidekiq_options retry: 4

    def perform(vm_id)
      vm = VirtualMachine.find(vm_id)
      vm.destroy!
    end
  end
end