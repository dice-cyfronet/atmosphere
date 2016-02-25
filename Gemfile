source 'https://rubygems.org'

# Declare your gem's dependencies in atmosphere.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# this is a hack to force a specific revision of azure gem
# against which Atmo was tested
gem 'azure',
    github: 'Azure/azure-sdk-for-ruby',
    branch: 'master',
    ref: 'e61400c9b8f184da74a1723495b503340218c637'

group :development do
  gem 'quiet_assets'

  # Better error page
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rubocop'
end

group :development, :test do
  gem 'pry-rails'

  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
end

group :test do
  # gem 'rspec-rails'
  gem 'rspec-sidekiq'
  # gem 'shoulda-matchers'
  gem 'generator_spec'

  # gem 'factory_girl'
  gem 'ffaker', '~>2.0.0'
  gem 'database_cleaner'

  gem 'codeclimate-test-reporter', require: nil

  gem 'highcharts-rails'
end
