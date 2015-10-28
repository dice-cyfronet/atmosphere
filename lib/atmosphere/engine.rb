require 'settingslogic'

require 'cancan'
require 'simple_form'
require 'gravtastic'
require 'role_model'
require 'enumerize'
require 'sentry-raven'
require 'influxdb'
require 'active_model_serializers'
require 'will_paginate'
require 'omniauth'
require 'fog'
require 'unf'
require 'redirus'

require 'bootstrap-sass'
require 'font-awesome-sass'
require 'nprogress-rails'
require 'jquery-rails'
require 'turbolinks'
require 'jquery-turbolinks'
require 'highcharts-rails'

require 'github-markup'
require 'redcarpet'

require 'draper'

module Atmosphere
  class Engine < ::Rails::Engine
    isolate_namespace Atmosphere

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match("#{root}/")
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer :static_assets do |app|
      app.middleware.use(::ActionDispatch::Static, "#{root}/public")
    end

    if Rails.env.test?
      initializer 'model_core.factories',
                  after: 'factory_girl.set_factory_paths' do
        if defined?(FactoryGirl)
          FactoryGirl.definition_file_paths <<
            File.expand_path('../../../spec/factories', __FILE__)
        end
      end
    end
  end
end
