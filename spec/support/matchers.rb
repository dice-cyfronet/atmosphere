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
    actual['type'] == expected.appliance_set_type.to_s
  end
end