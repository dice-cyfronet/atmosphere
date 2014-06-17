class Cloud::VmTagsManager

  def create_tags_for_vm(vm)
    users = vm.appliances.collect{|a| a.appliance_set}.collect{|a_set| a_set.user.login}.uniq.join(', ')
    VmTagsCreatorWorker.perform_async(vm.id_at_site, vm.compute_site.id, {'Name' => vm.name, 'Appliance type name' => vm.appliance_type.name, 'Users' => users})
  end

end