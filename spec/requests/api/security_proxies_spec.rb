require 'spec_helper'

describe API::SecurityProxies do
  include ApiHelpers

  let!(:owned_payload1) { create(:security_proxy, name: 'first/proxy', users: [owner1, owner2]) }
  let!(:owned_payload2) { create(:security_proxy, name: 'second/proxy', users: [owner1]) }
  let(:new_owned_payload) { {name: 'new/proxy', payload: 'payload'} }
  let(:new_owned_payload_with_owners) { {name: 'new/proxy/with/owners', payload: 'payload', owners: [owner1.login, owner2.login]}}

  def owned_payload_class
    SecurityProxy
  end

  def owned_payload_path
    "security_proxies"
  end

  include OwnedPayloadTests
end