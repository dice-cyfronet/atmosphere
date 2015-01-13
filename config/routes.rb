require 'sidekiq/web'

def json_resources(name)
  resources name, only: [:index, :show, :create, :update, :destroy]
end

Atmosphere::Engine.routes.draw do
  root 'home#index'

  devise_for  :users,
              class_name: 'Atmosphere::User',
              controllers: {
                omniauth_callbacks: 'atmosphere/users/omniauth_callbacks'
              },
              module: :devise

  get 'jobs/show'
  resource :profile, only: [:show, :update] do
    member do
      put :update_password
      put :reset_private_token
    end
  end

  constraint = ->(request) { request.env['warden'].authenticate? }
  constraints constraint do
    mount Sidekiq::Web, at: '/admin/sidekiq', as: :sidekiq
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
      resources :appliance_configuration_templates, except: [:show]
    end
    resources :compute_sites
    resources :virtual_machines, only: [:index, :show] do
      member do
        post :save_as_template
        post :reboot
      end
    end
    resources :virtual_machine_templates, except: [:new, :create]
    resources :user_keys, except: [:edit, :update]
    resources :funds
    resources :compute_site_funds, only: [:create, :destroy]
    resources :user_funds, only: [:create, :destroy, :update]
    resources :billing_logs, only: [:index]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :compute_sites, only: [:index, :show]

      resources :virtual_machine_flavors, only: [:index]

      json_resources :appliance_types

      get 'appliance_types/:id/endpoints/:service_name/:invocation_path' =>
          'appliance_types#endpoint_payload',
          as: 'appliance_types_endpoint_payload',
          constraints: { invocation_path: /[\w\.-]+(\/{0,1}[\w\.-]+)+/ },
          defaults: { format: :text }

      json_resources :port_mapping_templates
      resources :endpoints do
        member do
          get :descriptor
        end
      end
      json_resources :port_mapping_properties
      json_resources :appliance_configuration_templates
      resources :appliance_configuration_instances, only: [:index, :show]
      resources :http_mappings, only: [:index, :show, :update]
      resources :port_mappings, only: [:index, :show]
      json_resources :appliance_sets

      resources :appliances do
        member do
          get :endpoints
          post :action
        end
      end

      resources :dev_mode_property_sets, only: [:index, :show, :update]
      resources :virtual_machines, only: [:index, :show]
      resources :virtual_machine_templates, only: [:index]
      json_resources :users
      resources :user_keys, only: [:index, :show, :create, :destroy]

      get 'clew/appliance_instances' => 'clew#appliance_instances'
      get 'clew/appliance_types' => 'clew#appliance_types'
    end
  end

  get 'help' => 'help#index'
  get 'help/api' => 'help#api'
  get 'help/api/:category'  => 'help#api', as: 'help_api_file'
end
