def json_resources(name)
  resources name, only: [:index, :show, :create, :update, :destroy]
end

def owned_payload_resources(name)
  json_resources name
  get "#{name}/:name/payload" => "#{name}#payload", as: "#{name}_payload", constraints: {name: /#{OwnedPayloable.name_regex}/}, defaults: {format: :text}
end

Air::Application.routes.draw do
  resources :user_keys

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

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      json_resources :appliance_types
      json_resources :appliance_sets
      json_resources :users

      owned_payload_resources :security_proxies
      owned_payload_resources :security_policies
    end
  end

  get 'help' => 'help#index'
  get 'help/api' => 'help#api'
  get 'help/api/:category'  => 'help#api', as: 'help_api_file'

  get 'static' => 'static#index'
end
