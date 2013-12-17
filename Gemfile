source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.2'

# Supported DBs
gem 'mysql2', group: :mysql
gem 'pg', group: :postgres

# ... and provide means for referential integrity ...
gem 'foreigner'
# ... with some sugar over string enumerables
gem 'enumerize'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Air settings
gem 'settingslogic'

# Rendering forms
gem 'simple_form', '~>3.0.0'

# User avatar
gem 'gravtastic'

# Sending email when 500 is thrown
gem 'exception_notification'

# Security
gem 'devise', '~>3.2'
gem 'cancan'
gem 'role_model'
gem 'omniauth'
gem 'omniauth-vph', git: 'http://gitlab.dev.cyfronet.pl/atmosphere/omniauth-vph.git', branch: :master

gem 'redirus-worker', github: 'dice-cyfronet/redirus-worker', branch: :master, require: 'redirus/worker/proxy'

gem 'haml-rails'
gem 'bootstrap-sass', '~>3.0'

gem 'font-awesome-rails'

gem "active_model_serializers"
gem 'will_paginate', '~> 3.0.5'

#markdown in js
gem 'showdown-rails'

# Cross-Origin Resource Scharing for external UIs
gem 'rack-cors', :require => 'rack/cors'

# rendering documentation
gem 'redcarpet'
gem 'github-markup', require: 'github/markup'

# cloud client lib
gem 'fog', '~>1.18'
gem 'unf'

#delay and scheduled jobs
gem 'sinatra', require: nil
gem 'sidekiq'
gem 'clockwork'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development do
  gem 'annotate', github: 'ctran/annotate_models'
  gem 'quiet_assets'
  gem 'letter_opener'
  # gem 'rack-mini-profiler'

  # Better error page
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rails_best_practices'

  gem 'foreman'
end

group :development, :test do
  gem 'pry-rails'

  gem 'rspec-rails'
  gem 'shoulda-matchers'

  # Guard
  gem 'guard-rspec'
  gem 'spork-rails', github: 'sporkrb/spork-rails'
  gem 'guard-spork'
  gem 'libnotify'

  gem 'factory_girl'
  gem 'ffaker'
  gem 'database_cleaner'
end

group :test do
  gem 'rspec-sidekiq'
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

gem 'puma'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :old_air do
  gem 'multi_json', '~> 1.8.2'
  gem 'mongo', '~> 1.3.1'
  gem 'jnunemaker-validatable', '~> 1.8.4'
  gem 'plucky', '~> 0.3.6'
  gem 'mongo_mapper', '~> 0.8.6'
  gem 'sint_upper_model', '~> 0.1.9'
  gem 'sintmodel_vph', '~> 0.0.35'
end