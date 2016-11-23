source 'https://rubygems.org'

# Declare your gem's dependencies in atmosphere.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :development do
  gem 'quiet_assets'
  gem 'web-console', '3.3.0'
  gem 'rubocop'
end

group :development, :test do
  gem 'pry-rails'

  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'generator_spec'
  gem 'ffaker', '~> 2.3.0'
  gem 'database_cleaner'
  gem 'codeclimate-test-reporter', require: false
end
