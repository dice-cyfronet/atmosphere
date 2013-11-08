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
    actual['visible_for'] == expected.visible_for &&

    actual['preference_cpu'] == expected.preference_cpu &&
    actual['preference_memory'] == expected.preference_memory &&
    actual['preference_disk'] == expected.preference_disk &&

    #links
    actual['author'] == expected.user_id &&
    actual['security_proxy'] == expected.security_proxy_id
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

RSpec::Matchers.define :config_template_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['name'] == expected.name &&
    actual['payload'] == expected.payload &&
    actual['appliance_type_id'] == expected.appliance_type.id
  end
end


RSpec::Matchers.define :appliance_eq do |expected|
  match do |actual|
    actual['id'] == expected.id &&
    actual['appliance_set_id'] == expected.appliance_set_id &&
    actual['appliance_type_id'] == expected.appliance_type_id &&
    actual['appliance_configuration_instance_id'] == expected.appliance_configuration_instance_id
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

RSpec::Matchers.define :be_updated_by do |expected|
  match do |actual|
    (actual.name == expected[:name] || expected[:name].blank?) &&
    (actual.description == expected[:description] || expected[:description].blank?) &&
    (actual.shared == expected[:shared] || expected[:shared].blank?)  &&
    (actual.scalable == expected[:scalable] || expected[:scalable].blank?)  &&
    (expected[:visible_for].blank? || actual.visible_for.to_s == expected[:visible_for].to_s)  &&
    (actual.preference_cpu == expected[:preference_cpu] || expected[:preference_cpu].blank?)  &&
    (actual.preference_memory == expected[:preference_memory] || expected[:preference_memory].blank?)  &&
    (actual.preference_disk == expected[:preference_disk] || expected[:preference_disk].blank?)  &&
    (actual.security_proxy.id == expected[:security_proxy] || expected[:security_proxy].blank?)  &&
    (actual.author.id == expected[:author] || expected[:author].blank?)
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
    actual.id_at_site == fog_vm_data['id'] &&
    actual.name == fog_vm_data['name'] &&
    actual.state.to_s == fog_vm_data['state'].downcase &&
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
