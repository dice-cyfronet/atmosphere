$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'atmosphere/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'atmosphere'
  s.version     = Atmosphere::VERSION
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
  s.homepage    = 'https://github.com/dice-cyfronet/atmosphere/'
  s.summary     = 'Atmosphere cloud platform'
  s.description = 'Atmosphere cloud platform'
  s.license     = 'MIT'

  s.files = Dir[
                 '{app,config,db,lib,doc}/**/*',
                 'spec/factories/**/*',
                 'MIT-LICENSE',
                 'Rakefile',
                 'README.md'
  ]
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 5.0.0.1'
  s.add_dependency 'pg', '~> 0.19.0'
  s.add_dependency 'enumerize', '~> 2.0'
  s.add_dependency 'redirus', '~>0.2.1'
  s.add_dependency 'migratio', '~> 0.0.3'
  s.add_dependency 'sshkey', '~> 1.8.0'
  s.add_dependency 'active_model_serializers', '~> 0.8.0'

  # UI
  s.add_dependency 'sass-rails'
  s.add_dependency 'coffee-rails', '~> 4.2.0'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'turbolinks'
  s.add_dependency 'jquery-turbolinks'
  s.add_dependency 'nprogress-rails'
  s.add_dependency 'simple_form'
  s.add_dependency 'gravtastic'
  s.add_dependency 'haml-rails'
  s.add_dependency 'bootstrap-sass', '~> 3.3'
  s.add_dependency 'font-awesome-sass', '~> 4.7.0'
  s.add_dependency 'highcharts-rails', '~> 4.2.5'
  s.add_dependency 'redcarpet'
  s.add_dependency 'github-markup'

  # authentication and authorization
  s.add_dependency 'devise', '~> 4.2'
  s.add_dependency 'omniauth'
  s.add_dependency 'cancancan'
  s.add_dependency 'role_model'

  # cloud clients
  s.add_dependency 'fog', '~> 1.37.0'
  s.add_dependency 'unf', '~> 0.1.4'

  # delay jobs
  s.add_dependency 'sidekiq'
  s.add_dependency 'clockwork', '~> 2.0'

  # minitoring
  s.add_dependency 'zabbixapi'
  s.add_dependency 'influxdb'
  s.add_dependency 'sentry-raven'
end
