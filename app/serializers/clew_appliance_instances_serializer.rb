

class ClewApplianceInstancesSerializer < ActiveModel::Serializer

  attribute :appliances

  def appliances
    if object.nil?
      {}
    else
      object.appliances.map { |appl| map_appliance(appl) }
    end

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
        :compute_site => vm.compute_site,
        :virtual_machine_flavor => vm.virtual_machine_flavor,
        :port_mappings => vm.port_mappings
    }
  end


end

