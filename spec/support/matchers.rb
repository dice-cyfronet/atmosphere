RSpec::Matchers.define :owned_payload_eq do |expected|
  match do |actual|
    actual['name'] == expected.name
    actual['payload'] == expected.payload
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
    actual['name'] == expected.name
    actual['id'] == expected.id
    actual['priority'] == expected.priority
    actual['appliance_set_type'] == expected.appliance_set_type.to_s
  end
end

RSpec::Matchers.define :appliance_type_eq do |expected|
  match do |actual|
    actual['id'] == expected.id
    actual['name'] == expected.name
    actual['description'] == expected.description
    actual['shared'] == expected.shared
    actual['scalable'] == expected.scalable
    actual['visibility'] == expected.visibility

    actual['preference_cpu'] == expected.preference_cpu
    actual['preference_memory'] == expected.preference_memory
    actual['preference_disk'] == expected.preference_disk

    #links
    actual['author'] == expected.user_id
    actual['security_proxy'] == expected.security_proxy_id
  end
end

RSpec::Matchers.define :http_mapping_eq do |expected|
  match do |actual|
    actual['id'] == expected.id
    actual['url'] == expected.url
    actual['application_protocol'] == expected.application_protocol
  end
end

RSpec::Matchers.define :config_template_eq do |expected|
  match do |actual|
    actual['id'] = expected.id
    actual['name'] = expected.name
    actual['payload'] = expected.payload
    actual['appliance_type_id'] = expected.appliance_type.id
  end
end


RSpec::Matchers.define :appliance_eq do |expected|
  match do |actual|
    actual['id'] == expected.id
    actual['appliance_set_id'] == expected.appliance_set_id
    actual['appliance_type_id'] == expected.appliance_type_id
    actual['appliance_configuration_instance_id'] == expected.appliance_configuration_instance_id
  end
end

RSpec::Matchers.define :user_key_eq do |expected|
  match do |actual|
    actual['id'] == expected.id
    actual['name'] == expected.name
    actual['fingerprint'] == expected.fingerprint
    actual['public_key'] == expected.public_key
    actual['user_id'] == expected.user_id
  end
end

RSpec::Matchers.define :be_updated_by do |expected|
  match do |actual|
    actual.name == expected[:name] if expected[:name]
    actual.description == expected[:description] if expected[:description]
    actual.shared == expected[:shared] if expected[:shared]
    actual.scalable == expected[:scalable] if expected[:scalable]
    actual.visibility == expected[:visibility] if expected[:visibility]
    actual.preference_cpu == expected[:preference_cpu] if expected[:preference_cpu]
    actual.preference_memory == expected[:preference_memory] if expected[:preference_memory]
    actual.preference_disk == expected[:preference_disk] if expected[:preference_disk]
    actual.security_proxy.id == expected[:security_proxy] if expected[:security_proxy]
    actual.author.id == expected[:author] if expected[:author]
  end
end

RSpec::Matchers.define :vmt_fog_data_equals do |fog_vmt, site|
  match do |actual|
    actual.id_at_site == fog_vmt['id']
    actual.name == fog_vmt['name']
    actual.state == fog_vmt['status'].downcase.to_sym
    actual.compute_site == site
  end
end

RSpec::Matchers.define :vm_fog_data_equals do |fog_vm_data, template|
  match do |actual|
    actual.id_at_site == fog_vm_data['id']
    actual.name == fog_vm_data['name']
    actual.state == fog_vm_data['state'].downcase.to_sym
    actual.compute_site == template.compute_site
    actual.source_template == template
  end
end