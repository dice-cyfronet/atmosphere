require 'haml-rails'
require 'devise'
require "atmosphere/engine"

module Atmosphere

  # Default way to setup Atmosphere.
  def self.setup
      yield self
    end

  # configuration placeholder
  # mattr_accessor :config_param_name
  # @@config_param_name = default_value

  # If user credentials should be delegated into spawned VM than delegated
  # auth value can be used. It will automatically inject into every initial
  # configuration instance parameter with delegation_key value as a key
  # and result of delegate_auth method implemented in
  # /app/controllers/concerns/api/*/appliances_controller_ext.rb.
  mattr_accessor :delegation_initconf_key
end