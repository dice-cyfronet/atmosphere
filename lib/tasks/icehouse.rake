namespace :compute do
  desc "Attaches VMs to Appliance Types"
  task attach: :environment do
    puts "Scanning Icehouse compute site at CYF..."
    cs = ComputeSite.find_by(site_id: "cyfronet-icehouse")
    new_vmts = cs.virtual_machine_templates

    puts "Found #{cs.virtual_machine_templates.count.to_s} VMTs."

    change_ctr = 0

    new_vmts.each do |new_vmt|
      vmtid = new_vmt.name[5..-1]

      old_vmt = VirtualMachineTemplate.find_by(id_at_site: vmtid)

      if old_vmt.blank?
        puts "VMT #{new_vmt.name} has no matching source VMT found in repository. Skipping."
      elsif old_vmt.appliance_type.blank?
        puts "VMT #{new_vmt.name}: source VMT not bound to any appliance type. Skipping."
      elsif old_vmt.appliance_type.virtual_machine_templates.include? new_vmt
        puts "VMT #{new_vmt.name}: source appliance type alredy includes this VMT. Skipping."
      else
        puts "Binding VMT #{new_vmt.name} to appliance type #{old_vmt.appliance_type.name} and setting managed_by_atmosphere to true."
        old_vmt.appliance_type.virtual_machine_templates << new_vmt
        new_vmt.managed_by_atmosphere = true
        new_vmt.save
        change_ctr += 1
      end
    end
    puts "All done. #{change_ctr.to_s} VMTs registered."
  end
end
