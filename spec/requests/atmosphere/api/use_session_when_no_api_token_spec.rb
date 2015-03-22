require 'rails_helper'

describe 'Use session when no api token' do
  include ApiHelpers
  include Warden::Test::Helpers

  before { ActionController::Base.allow_forgery_protection = true }
  after { ActionController::Base.allow_forgery_protection = false }

  it 'use session when no token' do
    login_user

    get api('/users')

    expect(response.status).to eq 200
  end

  it 'requires token when request other then GET' do
    user = login_user
    at = create(:appliance_type, author: user)

    expect { delete api("/appliance_types/#{at.id}") }.
      to raise_error(ActionController::InvalidAuthenticityToken)
  end

  def login_user
    create(:user).tap { |user| login_as(user, scope: :user) }
  end
end
