require 'rails_helper'

describe Atmosphere::Api::V1::UsersController do
  include ApiHelpers

  let!(:user)  { create(:user) }
  let!(:user2) { create(:user) }
  let!(:admin) { create(:admin) }

  describe 'GET /users' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/users')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/users', user)
        expect(response.status).to eq 200
      end

      it 'returns basic information about users' do
        get api('/users', user)
        expect(users_response).to be_an Array
        expect(users_response.size).to eq 3

        expect(users_response[0]).to user_basic_eq user
        expect(users_response[1]).to user_basic_eq user2
        expect(users_response[2]).to user_basic_eq admin
      end
    end

    context 'when authenticated as admin' do
      it 'returns full information about users' do
        get api('/users', admin)
        expect(users_response[0]).to user_full_eq user
        expect(users_response[1]).to user_full_eq user2
        expect(users_response[2]).to user_full_eq admin
      end
    end

    context 'search' do
      it 'searches using login' do
        get api("/users?login=#{user.login}", user)
        expect(users_response.size).to eq 1
        expect(users_response[0]).to user_basic_eq user
      end
    end
  end

  describe 'GET /users/:id' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/users/#{user.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/users/#{user.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns basic information about users' do
        get api("/users/#{user.id}", user)
        expect(user_response).to user_basic_eq user
      end

      it 'return 404 Not found for not existing users' do
        get api("/users/not_existing", user)
        expect(response.status).to eq 404
      end
    end

    context 'when authenticated as admin' do
      it 'returns full information about users' do
        get api("/users/#{user.id}", admin)
        expect(user_response).to user_full_eq user
      end
    end
  end

  def users_response
    json_response['users']
  end

  def user_response
    json_response['user']
  end
end