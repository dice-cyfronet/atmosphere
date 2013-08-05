require 'api/api'

Air::Application.routes.draw do
  devise_for :users
  root to: 'home#index'

  mount API::API => '/api'
end
