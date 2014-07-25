

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
      :application_protocol => pmt.application_protocol,
      :http_mappings => pmt.http_mappings,
      :endpoints => pmt.endpoints
    }
  end

  def map_vm(vm)
    {
      :id => vm.id,
      :ip => vm.ip,
      :state => vm.state,
      :compute_site => map_cs(vm.compute_site),
      :virtual_machine_flavor => vm.virtual_machine_flavor,
      :port_mappings => vm.port_mappings
    }
  end

  def map_cs(cs)
    { :id => cs.id,
      :site_id => cs.site_id,
      :name => cs.name,
      :location => cs.location,
      :site_type => cs.site_type,
      :technology => cs.technology,
      :http_proxy_url => cs.http_proxy_url,
      :https_proxy_url => cs.https_proxy_url,
      :config => cs.config,
      :template_filters => cs.template_filters,
      :updated_at => cs.updated_at,
      :created_at => cs.created_at,
      :active => cs.active
    }
  end


end

