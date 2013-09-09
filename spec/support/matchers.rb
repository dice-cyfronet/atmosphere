RSpec::Matchers.define :owned_payload_eq do |expected|
  match do |actual|
    actual['name'] == expected.name
    actual['payload'] == expected.payload
    actual['owners'].size == names(expected).size
  end

  def names (expected)
    @names ||= expected.users.collect do |user|
      user.login
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