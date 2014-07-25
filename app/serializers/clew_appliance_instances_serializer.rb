

class ClewApplianceInstancesSerializer < ActiveModel::Serializer

  attribute :appliances

  def appliances
    appl_set = object[:appliance_set]
    if appl_set.nil?
      []
    else
      appl_set.appliances.map { |appl| map_appliance(appl) }
    end
  end

  def map_appliance(appliance)
    {
      :id => appliance.id,
      :name => appliance.name,
      :description => appliance.description,
      :state => appliance.state,
      :state_explanation => appliance.state_explanation,
      :amount_billed => appliance.amount_billed,
      :prepaid_until => appliance.prepaid_until,
      :port_mapping_templates  => appliance.appliance_type.port_mapping_templates.map { |pmt| map_pmt(pmt) },
      :virtual_machines => appliance.deployments.map { |depl| map_vm(depl.virtual_machine) }
    }
  end

  def map_pmt(pmt)
    {
        :id => pmt.id,
        :service_name => pmt.service_name,
        :target_port => pmt.target_port,
        :transport_protocol => pmt.transport_protocol,
        :http_mappings => pmt.http_mappings,
        :endpoints => pmt.endpoints
    }
  end

  def map_vm(vm)
    {
        :id => vm.id,
        :ip => vm.ip,
        :state => vm.state,
        :compute_site => vm.compute_site,
        :virtual_machine_flavor => vm.virtual_machine_flavor,
        :port_mappings => vm.port_mappings
    }
  end


end

