FactoryGirl.define do
  factory :virtual_machine_flavor, aliases: [:flavor],
    class: 'Atmosphere::VirtualMachineFlavor' do
    flavor_name { FactoryGirl.generate(:vm_flavor_name) }
    cpu { rand(max=16) + 1 }
    memory { rand(max=16384) + 512 }
    hdd { rand(max=1000) + 1 }
    hourly_cost { rand(max=100) + 1 }
  end

  sequence :vm_flavor_name do |n|
    "Flavor #{n}"
  end
end