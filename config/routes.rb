require 'api/api'

Air::Application.routes.draw do
  resources :virtual_machine_templates

  resources :compute_sites

  resources :virtual_machines

  namespace :admin do
    resources :appliance_sets, only: [:index, :show, :edit, :update, :destroy]
    resources :security_proxies
    resources :security_policies
  end

  devise_for :users
  root to: 'home#index'

  mount API::API => '/api'

  get 'help' => 'help#index'
  get 'help/api' => 'help#api'
end
