require 'rails_helper'

describe Api::V1::SecurityProxiesController do
  include ApiHelpers

  let!(:owned_payload1) { create(:security_proxy, name: 'first/proxy', users: [owner1, owner2]) }
  let!(:owned_payload2) { create(:security_proxy, name: 'second/proxy', users: [owner1]) }

  let(:new_owned_payload) do
    { security_proxy: {name: 'new/proxy', payload: 'payload'} }
  end

  let(:new_owned_payload_with_owners) do
    {
      security_proxy: {
        name: 'new/proxy/with/owners',
        payload: 'payload',
        owners: [owner1.id, owner2.id]
      }
    }
  end

  def owned_payload_class
    SecurityProxy
  end

  def owned_payload_path
    "security_proxies"
  end

  include OwnedPayloadTests
end