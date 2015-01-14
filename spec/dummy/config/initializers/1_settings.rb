class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env

  Settings['sidekiq'] ||= Settingslogic.new({})
  Settings.sidekiq['url'] ||= "redis://localhost:6379"
  Settings.sidekiq['namespace'] ||= "air"
end
