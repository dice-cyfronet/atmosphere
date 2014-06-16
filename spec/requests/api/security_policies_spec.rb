require 'rails_helper'

describe Api::V1::SecurityPoliciesController do
  include ApiHelpers

  let!(:owned_payload1) { create(:security_policy, name: 'first/policy', users: [owner1, owner2]) }
  let!(:owned_payload2) { create(:security_policy, name: 'second/policy', users: [owner1]) }

  let(:new_owned_payload) do
    { security_policy: {name: 'new/policy', payload: 'payload'} }
  end

  let(:new_owned_payload_with_owners) do
    {
      security_policy: {
        name: 'new/policy/with/owners',
        payload: 'payload',
        owners: [owner1.id, owner2.id]
      }
    }
  end

  def owned_payload_class
    SecurityPolicy
  end

  def owned_payload_path
    "security_policies"
  end

  include OwnedPayloadTests
end