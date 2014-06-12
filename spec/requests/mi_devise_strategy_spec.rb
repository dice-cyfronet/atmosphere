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
    allow(Air.config.vph).to receive(:host).and_return(host)
    allow(Air.config.vph).to receive(:roles_map).and_return(roles_map)
    allow(Air.config.vph).to receive(:ssl_verify).and_return(false)
  end

  it 'authenticate with valid master interface token key and value through params' do
    login_as('admin', 'developer')

    get api("/appliance_sets?mi_ticket=#{valid_mi_token}")

    expect(response.status).to eq 200
  end

  it 'authenticate with valid master interface token key and value through header' do
    login_as('admin', 'developer')

    get api('/appliance_sets'), nil, {'MI-TICKET' => valid_mi_token}

    expect(response.status).to eq 200
  end

  it 'sets user mi ticket in current user object' do
    login_as('admin', 'developer')

    get api("/appliance_sets?mi_ticket=#{valid_mi_token}")

    expect(controller.current_user.mi_ticket).to eq valid_mi_token
  end

  it 'does not authenticate with improper authentication token key' do
    get api("/appliance_sets?mi_ticket=NOT_VALID")
    expect(response.status).to eq 401
  end

  it 'sudo to other user when admin' do
    login_as('admin', 'developer')
    other_user = create(:user, login: 'other_user')

    get api("/appliance_sets?mi_ticket=#{valid_mi_token}&sudo=other_user")

    expect(response.status).to eq 200
    expect(controller.current_user.login).to eq 'other_user'
  end

  it 'does not allow sudo for non admin' do
    login_as('developer')

    get api("/appliance_sets?mi_ticket=#{valid_mi_token}&sudo=other_user")

    expect(response.status).to eq 403
    expect(json_response['error']).to eq 'Must be admin to use sudo'
  end

  it 'return 404 when user for sudo not found' do
    login_as('admin')

    get api("/appliance_sets?mi_ticket=#{valid_mi_token}&sudo=other_user")

    expect(response.status).to eq 404
    expect(json_response['error']).to eq 'No user login for: other_user'
  end

  def login_as(*roles)
    allow(::OmniAuth::Vph::Adaptor).to receive(:new).with({host: host, roles_map: roles_map, ssl_verify: false}).and_return(adaptor)

    allow(adaptor).to receive(:user_info).with(valid_mi_token).and_return(mi_user_info)

    allow(adaptor).to receive(:map_user).with(mi_user_info).and_return({
        'email' => 'user@foobar.pl',
        'login' => 'foobar',
        'full_name' => 'Foo Bar',
        'roles' => roles
      })
  end
end