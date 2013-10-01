class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env


  Settings['config_param'] ||= Settingslogic.new({})
  Settings.config_param['regexp'] ||= '#{\w*}'
  Settings.config_param['range'] ||= '2..-2'
end