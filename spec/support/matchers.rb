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