source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'

# Use mysql as the database for Active Record
gem 'mysql2'
# and provide means for referential integrity
gem 'foreigner'

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
gem 'simple_form'

# Security
gem 'devise', '~>3.0.0'
gem 'cancan'

gem 'haml-rails'
gem 'bootstrap-sass', :git => 'git://github.com/thomas-mcdonald/bootstrap-sass.git', :branch => '3'
gem 'font-awesome-rails'

# API
gem 'grape'
gem 'grape-entity'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development do
  gem 'annotate', git: 'https://github.com/ctran/annotate_models.git'
  gem 'quiet_assets'
  gem 'letter_opener'
  gem 'rack-mini-profiler'

  # Better error page
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rails_best_practices'
end

group :development, :test do
  gem 'pry-rails'

  gem 'rspec-rails'
  gem 'shoulda-matchers'

  # Guard
  gem 'guard-rspec'
  gem 'spork-rails', git: 'https://github.com/sporkrb/spork-rails.git'
  gem 'guard-spork'
  gem 'libnotify'

  gem 'factory_girl'
  gem 'ffaker'
  gem 'database_cleaner'
end


# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
