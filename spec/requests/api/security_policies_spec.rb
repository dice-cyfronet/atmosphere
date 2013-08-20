require 'spec_helper'

describe API::SecurityPolicies do
  include ApiHelpers

  let!(:owned_payload1) { create(:security_policy, name: 'first/policy', users: [owner1, owner2]) }
  let!(:owned_payload2) { create(:security_policy, name: 'second/policy', users: [owner1]) }
  let(:new_owned_payload) { {name: 'new/policy', payload: 'payload'} }
  let(:new_owned_payload_with_owners) { {name: 'new/policy/with/owners', payload: 'payload', owners: [owner1.login, owner2.login]}}

  def owned_payload_class
    SecurityPolicy
  end

  def owned_payload_path
    "security_policies"
  end

  include OwnedPayloadTests
end