module Atmosphere
  class Cloud::VmTagsManager
    def initialize(vm)
      @vm = vm
    end

    def execute
      users = User.with_vm(vm).collect{|u| u.login}.join(', ')
      VmTagsCreatorWorker.perform_async(vm.id,
        {'Name' => vm.name, 'Appliance type name' => vm.appliance_type.name, 'Users' => users}
      )
    end

    private

    attr_reader :vm
  end
end
