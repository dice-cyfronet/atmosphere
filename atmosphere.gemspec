$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'atmosphere/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'Atmosphere'
  s.version     = Vphshare::VERSION
  s.authors     = [
                    'Marek Kasztelnik',
                    'Tomasz Bartynski',
                    'Tomasz Gubala',
                    'Bartosz Wilk',
                    'Piotr Nowakowski',
                    'Pawel Suder'
                  ]
  s.email       = [
                    'mkasztelnik@gmail.com',
                    'tomek.bartynski@gmail.com',
                    't.gubala@cyfronet.pl',
                    'b.wilk@cyfronet.pl',
                    'ymnowako@cyf-kr.edu.pl',
                    'pawel@suder.info'
                  ]
  s.homepage    = 'https://gitlab.dev.cyfronet.pl/atmosphere/air/'
  s.summary     = 'Atmosphere cloud platform'
  s.description = 'Atmosphere cloud platform'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 4.1.6'
  s.add_dependency 'pg'
  s.add_dependency 'foreigner'
  s.add_dependency 'enumerize'
  s.add_dependency 'sass-rails', '~> 4.0.3'
  s.add_dependency 'coffee-rails', '~> 4.0.0'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'turbolinks'
  s.add_dependency 'jquery-turbolinks'
  s.add_dependency 'nprogress-rails'
  s.add_dependency 'settingslogic'
  s.add_dependency 'simple_form'
  s.add_dependency 'gravtastic'
  s.add_dependency 'devise', '~>3.2'
  s.add_dependency 'cancan'
  s.add_dependency 'role_model'
  s.add_dependency 'haml-rails'
  s.add_dependency 'bootstrap-sass', '~>3.2'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'active_model_serializers', '~>0.8.0'
  s.add_dependency 'zabbixapi'
  s.add_dependency 'showdown-rails'
  s.add_dependency 'redcarpet'
  s.add_dependency 'github-markup'
  s.add_dependency 'fog'
  s.add_dependency 'unf'
  s.add_dependency 'sinatra'
  s.add_dependency 'sidekiq'
  s.add_dependency 'clockwork'
  s.add_dependency 'influxdb'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'shoulda-matchers'
end
