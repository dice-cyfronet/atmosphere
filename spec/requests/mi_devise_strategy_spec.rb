require 'rails_helper'

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
    allow(Air.config.vph).to receive(:host).and_return(host)
    allow(Air.config.vph).to receive(:roles_map).and_return(roles_map)
    allow(Air.config.vph).to receive(:ssl_verify).and_return(false)

    allow(::OmniAuth::Vph::Adaptor).to receive(:new).with({host: host, roles_map: roles_map, ssl_verify: false}).and_return(adaptor)

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

  it 'authenticate with valid master interface token key and value through header' do
    get api('/appliance_sets'), nil, {'MI-TICKET' => valid_mi_token}
    expect(response.status).to eq 200
  end

  it 'sets user mi ticket in current user object' do
    get api("/appliance_sets?mi_ticket=#{valid_mi_token}")
    expect(controller.current_user.mi_ticket).to eq valid_mi_token
  end

  it 'does not authenticate with improper authentication token key' do
    get api("/appliance_sets?mi_ticket=NOT_VALID")
    expect(response.status).to eq 401
  end
end