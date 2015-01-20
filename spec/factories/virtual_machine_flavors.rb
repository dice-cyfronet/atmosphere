FactoryGirl.define do
  factory :virtual_machine_flavor, aliases: [:flavor],
    class: 'Atmosphere::VirtualMachineFlavor' do
    flavor_name { FactoryGirl.generate(:vm_flavor_name) }
    cpu { rand(max=16) + 1 }
    memory { rand(max=16384) + 512 }
    hdd { rand(max=1000) + 1 }
    hourly_cost { rand(max=100) + 1 }

    # Create a new incarnation record for this flavor (bind to os_family and rewrite price
    after(:build) do |vmf|
      vmf_osf = Atmosphere::VirtualMachineFlavorOSFamily.new
      vmf_osf.virtual_machine_flavor = vmf
      vmf_osf.os_family = Atmosphere::OSFamily.first
      vmf_osf.hourly_cost = vmf.hourly_cost
      vmf_osf.save
    end

  end

  sequence :vm_flavor_name do |n|
    "Flavor #{n}"
  end

end