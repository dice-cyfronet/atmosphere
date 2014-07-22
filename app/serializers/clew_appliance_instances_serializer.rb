

class ClewApplianceInstancesSerializer < ActiveModel::Serializer

  attribute :appliances

  def appliances
    object.appliances.map { |appl| map_appliance(appl) }
  end

  def map_appliance(appliance)
    {
      :id => appliance.id,
      :port_mapping_templates  => appliance.appliance_type.port_mapping_templates.map { |pmt| map_pmt(pmt) },
      :virtual_machines => appliance.deployments.map { |depl| map_vm(depl.virtual_machine) }
    }
  end

  def map_pmt(pmt)
    {
        :id => pmt.id,
        :http_mappings => pmt.http_mappings,
        :endpoints => pmt.endpoints
    }
  end

  def map_vm(vm)
    {
        :id => vm.id,
        :port_mappings => vm.port_mappings,
        :virtual_machine_flavor => vm.virtual_machine_flavor
    }
  end


end

