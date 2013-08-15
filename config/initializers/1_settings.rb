class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env
end