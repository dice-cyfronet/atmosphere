module Atmosphere
  class Cloud::VmTagsManager
    def create_tags_for_vm(vm)
      users = User.with_vm(vm).collect{|u| u.login}.join(', ')
      VmTagsCreatorWorker.perform_async(vm.id,
        {'Name' => vm.name, 'Appliance type name' => vm.appliance_type.name, 'Users' => users}
      )
    end
  end
end
