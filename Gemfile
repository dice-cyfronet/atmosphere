source 'https://rubygems.org'

# Declare your gem's dependencies in atmosphere.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

gem 'redirus-worker', github: 'dice-cyfronet/redirus-worker', branch: :master, require: 'redirus/worker/proxy'

group :development do
  gem 'annotate'
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

  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
  gem 'guard-spring'
end

group :test do
  # gem 'rspec-rails'
  # gem 'rspec-sidekiq'
  gem 'rspec-sidekiq', github: 'yelled3/rspec-sidekiq', branch: 'rspec3-beta'
  # gem 'shoulda-matchers'

  # gem 'factory_girl'
  gem 'ffaker'
  gem 'database_cleaner'
end
