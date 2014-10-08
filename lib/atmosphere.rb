require 'haml-rails'
require 'devise'
require "atmosphere/engine"

module Atmosphere

  # Default way to setup Atmosphere.
  def self.setup
      yield self
    end

  # If user credentials should be delegated into spawned VM than delegated
  # auth value can be used. It will automatically inject into every initial
  # configuration instance parameter with delegation_key value as a key
  # and result of delegate_auth method implemented in
  # /app/controllers/concerns/api/*/appliances_controller_ext.rb.
  mattr_accessor :delegation_initconf_key

  # List of additional resources which should be presented while login
  # as admin user. List should be namespaced with router name. For main
  # rails application use following format:
  #
  #  {
  #    main_app: { AdditionalResourceViewsToShow }
  #  }
  mattr_accessor :admin_entites_ext
  @@admin_entites_ext = {}

  def self.admin_entities
    entities = {
      atmosphere: [
        Atmosphere::ApplianceType,
        Atmosphere::ApplianceSet,
        Atmosphere::ComputeSite,
        Atmosphere::VirtualMachine,
        Atmosphere::VirtualMachineTemplate,
        Atmosphere::UserKey
      ]
    }

    entities.merge(admin_entites_ext)
  end
end