if Air.config['raven_dsn']
  require 'raven'

  Raven.configure do |config|
    config.dsn = Air.config.raven_dsn
  end
end