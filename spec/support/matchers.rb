RSpec::Matchers.define :owned_payload_eq do |expected|
  match do |actual|
    actual['name'] == expected.name &&
    actual['payload'] == expected.payload &&
    actual['owners'].size == ids(expected).size
  end

  def ids (expected)
    @names ||= expected.users.collect do |user|
      user.id
    end
  end
end

RSpec::Matchers.define :appliance_set_eq do |expected|
  match do |actual|
    actual['name'] == expected.name &&
    actual['id'] == expected.id &&
    actual['priority'] == expected.priority &&
    actual['appliance_set_type'] == expected.appliance_set_type.to_s
  end
end

RSpec::Matchers.define :appliance_type_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['description'] == expected.description &&
    actual['shared'] == expected.shared &&
    actual['scalable'] == expected.scalable &&
    actual['visible_to'] == expected.visible_to &&

    actual['preference_cpu'] == expected.preference_cpu &&
    actual['preference_memory'] == expected.preference_memory &&
    actual['preference_disk'] == expected.preference_disk &&

    #links
    actual['author_id'] == expected.user_id &&
    actual['security_proxy_id'] == expected.security_proxy_id
  end
end

RSpec::Matchers.define :basic_appliance_type_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['description'] == expected.description
  end
end

RSpec::Matchers.define :http_mapping_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
        actual['url'] == expected.url &&
        actual['application_protocol'] == expected.application_protocol &&
        actual['appliance_id'] == expected.appliance_id &&
        actual['port_mapping_template_id'] == expected.port_mapping_template_id
  end
end

RSpec::Matchers.define :port_mapping_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
        actual['public_ip'] == expected.public_ip &&
        actual['source_port'] == expected.source_port &&
        actual['port_mapping_template_id'] == expected.port_mapping_template.id &&
        actual['virtual_machine_id'] == expected.virtual_machine.id
  end
end

RSpec::Matchers.define :http_mapping_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['url'] == expected.url &&
    actual['application_protocol'] == expected.application_protocol &&
    actual['appliance_id'] == expected.appliance_id &&
    actual['port_mapping_template_id'] == expected.port_mapping_template_id
  end
end

RSpec::Matchers.define :port_mapping_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['public_ip'] == expected.public_ip &&
    actual['source_port'] == expected.source_port &&
    actual['port_mapping_template_id'] == expected.port_mapping_template.id &&
    actual['virtual_machine_id'] == expected.virtual_machine.id
  end
end

RSpec::Matchers.define :config_template_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['payload'] == expected.payload &&
    actual['appliance_type_id'] == expected.appliance_type.id
  end
end

RSpec::Matchers.define :config_instance_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
        actual['payload'] == expected.payload &&
        actual['appliance_configuration_template_id'] == expected.appliance_configuration_template.id
  end
end

RSpec::Matchers.define :config_instance_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['payload'] == expected.payload &&
    actual['appliance_configuration_template_id'] == expected.appliance_configuration_template.id
  end
end

RSpec::Matchers.define :port_mapping_template_eq do |expected|
  match do |actual|
    (actual['id'] == expected.id) &&
    (actual['transport_protocol'] == expected.transport_protocol) &&
    (actual['application_protocol'] == expected.application_protocol) &&
    (actual['service_name'] == expected.service_name) &&
    (actual['target_port'] == expected.target_port) &&
    ((expected.appliance_type && (actual['appliance_type_id'] == expected.appliance_type_id)) or
     (expected.dev_mode_property_set && (actual['dev_mode_property_set_id'] == expected.dev_mode_property_set.id)))
  end
end

RSpec::Matchers.define :be_updated_by_port_mapping_template do |expected|
  match do |actual|
    (actual['transport_protocol'] == expected[:transport_protocol] || expected[:transport_protocol].blank?) &&
        (actual['application_protocol'] == expected[:application_protocol] || expected[:application_protocol].blank?) &&
        (actual['service_name'] == expected[:service_name] || expected[:service_name].blank?) &&
        (actual['target_port'] == expected[:target_port] || expected[:target_port].blank?) &&
        ((actual['appliance_type_id'] == expected[:appliance_type_id]) or (actual['dev_mode_property_set_id'] == expected[:dev_mode_property_set_id]) or
            (expected[:appliance_type_id].blank? && expected[:dev_mode_property_set_id].blank?))
  end
end

RSpec::Matchers.define :port_mapping_property_eq do |expected|
  match do |actual|
    (actual['id'] == expected.id) &&
    (actual['key'] == expected.key) &&
    (actual['value'] == expected.value) &&
    ((expected.port_mapping_template && (actual['port_mapping_template_id'] == expected.port_mapping_template_id)) or
        (expected.compute_site && (actual['compute_site_id'] == expected.compute_site.id)))
  end
end

RSpec::Matchers.define :be_updated_by_port_mapping_property do |expected|
  match do |actual|
    (actual['key'] == expected[:key] || expected[:key].blank?) &&
    (actual['value'] == expected[:value] || expected[:value].blank?) &&
    ((actual['port_mapping_template_id'] == expected[:port_mapping_template_id]) or
        (actual['compute_site_id'] == expected[:compute_site_id]) or
        (expected[:port_mapping_template_id].blank? && expected[:compute_site_id].blank?))
  end
end

RSpec::Matchers.define :endpoint_eq do |expected|
  match do |actual|
    (actual['id'] == expected.id) &&
    (actual['name'] == expected.name) &&
    (actual['description'] == expected.description) &&
    (actual['descriptor'] == expected.descriptor) &&
    (actual['endpoint_type'] == expected.endpoint_type) &&
    (actual['invocation_path'] == expected.invocation_path) &&
    (actual['port_mapping_template_id'] == expected.port_mapping_template_id)
  end
end

RSpec::Matchers.define :basic_endpoint_eq do |expected|
  match do |actual|
    (actual['id'] == expected.id) &&
    (actual['name'] == expected.name) &&
    (actual['description'] == expected.description) &&
    (actual['endpoint_type'] == expected.endpoint_type.to_s) &&
    (actual['url'] == descriptor_api_v1_endpoint_url(expected.id))
  end
end

RSpec::Matchers.define :be_updated_by_endpoint do |expected|
  match do |actual|
    (actual['name'] == expected[:name] || expected[:name].blank?) &&
    (actual['description'] == expected[:description] || expected[:description].blank?) &&
    (actual['descriptor'] == expected[:descriptor] || expected[:descriptor].blank?) &&
    (actual['endpoint_type'] == expected[:endpoint_type] || expected[:endpoint_type].blank?) &&
    (actual['port_mapping_template_id'] == expected[:port_mapping_template_id] || expected[:port_mapping_template_id].blank?)
  end
end

RSpec::Matchers.define :appliance_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['appliance_set_id'] == expected.appliance_set_id &&
    actual['appliance_type_id'] == expected.appliance_type_id &&
    actual['appliance_configuration_instance_id'] == expected.appliance_configuration_instance_id &&
    actual['state'] == expected.state &&
    actual['state_explanation'] == expected.state_explanation

  end
end

RSpec::Matchers.define :dev_props_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['appliance_id'] == expected.appliance.id &&
    actual['name'] == expected.name &&
    actual['description'] == expected.description &&
    actual['shared'] == expected.shared &&
    actual['scalable'] == expected.scalable &&
    actual['preference_cpu'] == expected.preference_cpu &&
    actual['preference_memory'] == expected.preference_memory &&
    actual['preference_disk'] == expected.preference_disk &&
    (!expected.security_proxy || actual['security_proxy_id'] == expected.security_proxy.id) &&
    actual['port_mapping_template_ids'] == expected.port_mapping_templates.collect(&:id)
  end
end

RSpec::Matchers.define :dev_props_be_updated_by do |expected|
  match do |actual|
    (actual.name == expected[:name] || expected[:name].blank?) &&
    (actual.description == expected[:description] || expected[:description].blank?) &&
    (actual.shared == expected[:shared] || expected[:shared].blank?)  &&
    (actual.scalable == expected[:scalable] || expected[:scalable].blank?)  &&
    (actual.preference_cpu == expected[:preference_cpu] || expected[:preference_cpu].blank?)  &&
    (actual.preference_memory == expected[:preference_memory] || expected[:preference_memory].blank?)  &&
    (actual.preference_disk == expected[:preference_disk] || expected[:preference_disk].blank?)  &&
    (expected[:security_proxy_id].blank? || actual.security_proxy.id == expected[:security_proxy_id])
  end
end

RSpec::Matchers.define :user_key_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['fingerprint'] == expected.fingerprint &&
    actual['public_key'] == expected.public_key &&
    actual['user_id'] == expected.user_id
  end
end

RSpec::Matchers.define :vm_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['id_at_site'] == expected.id_at_site &&
    actual['name'] == expected.name &&
    actual['state'] == expected.state.to_s &&
    actual['ip'] == expected.ip &&
    actual['compute_site_id'] == expected.compute_site_id
    # admin
    # actual['virtual_machine_template_id'] == expected.virtual_machine_template_id
    # actual['appliance_ids'] == TODO
  end
end

RSpec::Matchers.define :flavor_eq do |expected|
  match do |actual|
    actual.id_at_site == expected.id &&
    actual.cpu == expected.vcpus &&
    actual.memory == expected.ram &&
    actual.hdd == expected.disk &&
    actual.flavor_name == expected.name
  end
end


RSpec::Matchers.define :at_be_updated_by do |expected|
  match do |actual|
    (actual.name == expected[:name] || expected[:name].blank?) &&
    (actual.description == expected[:description] || expected[:description].blank?) &&
    (actual.shared == expected[:shared] || expected[:shared].blank?)  &&
    (actual.scalable == expected[:scalable] || expected[:scalable].blank?)  &&
    (expected[:visible_to].blank? || actual.visible_to.to_s == expected[:visible_to].to_s)  &&
    (actual.preference_cpu == expected[:preference_cpu] || expected[:preference_cpu].blank?)  &&
    (actual.preference_memory == expected[:preference_memory] || expected[:preference_memory].blank?)  &&
    (actual.preference_disk == expected[:preference_disk] || expected[:preference_disk].blank?)  &&
    (expected[:security_proxy_id].blank? || actual.security_proxy.id == expected[:security_proxy_id])  &&
    (actual.author.id == expected[:author_id] || expected[:author_id].blank?)
  end
end

RSpec::Matchers.define :vmt_fog_data_equals do |fog_vmt, site|
  match do |actual|
    actual.id_at_site == fog_vmt['id'] &&
    actual.name == fog_vmt['name'] &&
    actual.state.to_s == fog_vmt['status'].downcase &&
    actual.compute_site == site
  end
end

RSpec::Matchers.define :vm_fog_data_equals do |fog_vm_data, template|
  match do |actual|
    actual.id_at_site == fog_vm_data.id &&
    actual.name == fog_vm_data.name &&
    actual.state.to_s == fog_vm_data.state.downcase &&
    actual.compute_site == template.compute_site &&
    actual.source_template == template
  end
end

RSpec::Matchers.define :compute_site_basic_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['site_id'] == expected.site_id &&
    actual['name'] == expected.name &&
    actual['location'] == expected.location &&
    actual['site_type'] == expected.site_type &&
    actual['technology'] == expected.technology &&
    actual['config'] == nil
  end
end

RSpec::Matchers.define :compute_site_full_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['site_id'] == expected.site_id &&
    actual['name'] == expected.name &&
    actual['location'] == expected.location &&
    actual['site_type'] == expected.site_type &&
    actual['technology'] == expected.technology &&
    actual['config'] == expected.config
  end
end

RSpec::Matchers.define :appl_endpoint_eq do |endpoint, urls|
  match do |actual|
    actual['id'] == endpoint.id &&
    actual['type'] == endpoint.endpoint_type.to_s &&
    (actual['urls'] - urls).blank?
  end
end

RSpec::Matchers.define :user_basic_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['login'] == expected.login &&
    actual['full_name'] == expected.full_name &&
    actual.keys.size == 3
  end
end

RSpec::Matchers.define :user_full_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['login'] == expected.login &&
    actual['full_name'] == expected.full_name &&
    actual['email'] == expected.email &&
    actual['roles'] == expected.roles.to_a.collect(&:to_s)
  end
end