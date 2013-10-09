require 'spec_helper'

describe Devise::Strategies::MiTokenAuthenticatable do
  include ApiHelpers

  let(:adaptor) { double }
  let(:host) { 'http://mi.host'}
  let(:roles_map) do
    {
      'cloudadmin' => 'admin',
      'developer' => 'developer'
    }
  end
  let(:valid_mi_token) { 'VALID_MI_TOKEN' }

  let(:mi_user_info) { { "mi" => "user details" } }

  before do
    Air.config.vph.stub(:host).and_return(host)
    Air.config.vph.stub(:roles_map).and_return(roles_map)

    ::OmniAuth::Vph::Adaptor.stub(:new).with({host: host, roles_map: roles_map}).and_return(adaptor)

    allow(adaptor).to receive(:user_info).with(valid_mi_token).and_return(mi_user_info)

    allow(adaptor).to receive(:map_user).with(mi_user_info).and_return({
        'email' => 'user@foobar.pl',
        'login' => 'foobar',
        'full_name' => 'Foo Bar',
        'roles' => ['admin', 'developer']
      })
  end

  it 'authenticate with valid master interface token key and value through params' do
    get api("/appliance_sets?mi_ticket=#{valid_mi_token}")
    expect(response.status).to eq 200
  end

  it 'does not authenticate with improper authentication token key' do
    get api("/appliance_sets?mi_ticket=NOT_VALID")
    expect(response.status).to eq 401
  end
end