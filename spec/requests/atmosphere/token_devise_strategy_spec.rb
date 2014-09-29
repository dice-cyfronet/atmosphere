require 'spec_helper'

describe Devise::Strategies::TokenAuthenticatable do
  include ApiHelpers

  let(:valid_token) { 'valid'}

  it 'authenticate with valid master interface token key and value through params' do
    login_as('admin', 'developer')

    get api("/appliance_sets?private_token=#{valid_token}")

    expect(response.status).to eq 200
  end

  it 'authenticate with valid master interface token key and value through header' do
    login_as('admin', 'developer')

    get api('/appliance_sets'), nil, {'PRIVATE-TOKEN' => valid_token}

    expect(response.status).to eq 200
  end

  it 'does not authenticate with improper authentication token key' do
    get api("/appliance_sets?private_token=NOT_VALID")
    expect(response.status).to eq 401
  end

  it 'sudo to other user when admin' do
    login_as('admin', 'developer')
    other_user = create(:user, login: 'other_user')

    get api("/appliance_sets?private_token=#{valid_token}&sudo=other_user")

    expect(response.status).to eq 200
    expect(controller.current_user.login).to eq 'other_user'
  end

  it 'does not allow sudo for non admin' do
    login_as('developer')

    get api("/appliance_sets?private_token=#{valid_token}&sudo=other_user")

    expect(response.status).to eq 403
    expect(json_response['error']).to eq 'Must be admin to use sudo'
  end

  it 'return 404 when user for sudo not found' do
    login_as('admin')

    get api("/appliance_sets?private_token=#{valid_token}&sudo=other_user")

    expect(response.status).to eq 404
    expect(json_response['error']).to eq 'No user login for: other_user'
  end

  def login_as(*roles)
    create(:user, authentication_token: valid_token, roles: roles)
  end
end