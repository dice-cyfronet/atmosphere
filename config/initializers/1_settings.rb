class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env


  Settings['config_param'] ||= Settingslogic.new({})
  Settings.config_param['regexp'] ||= '#{\w*}'
  Settings.config_param['range'] ||= '2..-2'

  Settings['vph'] ||= Settingslogic.new({})
  Settings.vph['enabled'] = false if Settings.vph['enabled'].nil?

  Settings['sidekiq'] ||= Settingslogic.new({})
  Settings.sidekiq['url'] ||= "redis://localhost:6379"
  Settings.sidekiq['namespace'] ||= "air"

  Settings['optimizer'] ||= Settings.new({})
  Settings.optimizer['max_appl_no'] ||= 5
end