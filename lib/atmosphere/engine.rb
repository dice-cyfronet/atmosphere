require 'settingslogic'
require 'devise'
require 'cancan'
require 'simple_form'
require 'gravtastic'
require 'role_model'
require 'foreigner'
require 'enumerize'
require 'sentry-raven'
require 'influxdb'
require 'active_model_serializers'
require 'will_paginate'
require 'omniauth-vph'

module Atmosphere
  class Engine < ::Rails::Engine
    isolate_namespace Atmosphere

    config.generators do |g|
      g.test_framework      :rspec,        fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end