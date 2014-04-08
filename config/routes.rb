require 'sidekiq/web'

def json_resources(name)
  resources name, only: [:index, :show, :create, :update, :destroy]
  yield if block_given?
end

def owned_payload_resources(name)
  json_resources name
  get "#{name}/:name/payload" => "#{name}#payload", as: "#{name}_payload", constraints: {name: /#{OwnedPayloable.name_regex}/}, defaults: {format: :text}
end

Air::Application.routes.draw do

  get "jobs/show"
  resource :profile, only: [:show, :update] do
    member do
      put :update_password
      put :reset_private_token
    end
  end

  constraint = lambda { |request| request.env["warden"].authenticate? }
  constraints constraint do
    mount Sidekiq::Web, at: "/admin/sidekiq", as: :sidekiq
    get 'admin/jobs' => 'admin/jobs#show', as: :jobs
  end


  namespace :admin do
    resources :appliance_sets, only: [:index, :show, :edit, :update, :destroy]
    resources :appliance_types do
      member do
        put :assign_virtual_machine_template
      end
      resources :port_mapping_templates, except: [:show] do
        resources :endpoints, except: [:show]
      end
    end
    resources :security_proxies
    resources :security_policies
    resources :compute_sites
    resources :virtual_machines, only: [:index, :show] do
      member do
        post :save_as_template
        post :reboot
      end
    end
    resources :virtual_machine_templates, except: [:new, :create]
    resources :user_keys, except: [:edit, :update]
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  root to: 'home#index'

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      resources :compute_sites, only: [:index, :show]

      json_resources :appliance_types
      get 'appliance_types/:id/endpoints/:service_name/:invocation_path' => 'appliance_types#endpoint_payload', as: 'appliance_types_endpoint_payload', constraints: {invocation_path: /#{OwnedPayloable.name_regex}/}, defaults: {format: :text}
      resources :appliance_endpoints, only: [:index, :show]

      json_resources :port_mapping_templates
      resources :endpoints do
        member do
          get :descriptor
        end
      end
      json_resources :port_mapping_properties
      json_resources :appliance_configuration_templates
      resources :appliance_configuration_instances, only: [:index, :show]
      resources :http_mappings, only: [:index, :show]
      resources :port_mappings, only: [:index, :show]
      json_resources :appliance_sets

      resources :appliances do
        member do
          get :endpoints
        end
      end

      resources :dev_mode_property_sets, only: [:index, :show, :update]
      resources :virtual_machines, only: [:index, :show]
      resources :virtual_machine_templates, only: [:index]
      json_resources :users
      resources :user_keys, only: [:index, :show, :create, :destroy]

      owned_payload_resources :security_proxies
      owned_payload_resources :security_policies
    end
  end

  get 'help' => 'help#index'
  get 'help/api' => 'help#api'
  get 'help/api/:category'  => 'help#api', as: 'help_api_file'
end
