class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env

  class << self
    def header_token_authentication_key
      to_header_key(token_authentication_key)
    end

    def header_mi_authentication_key
      to_header_key(mi_authentication_key)
    end

    private

    def to_header_key(key)
      key.upcase.gsub(/_/, '-')
    end
  end


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

  Settings['token_authentication_key'] ||= 'private_token'
  Settings['mi_authentication_key']    ||= 'mi_ticket'
end