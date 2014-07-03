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

    def at_pdp_class
      Settings['at_pdp'] ?
        Settings.at_pdp.constantize : DefaultPdp
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
  Settings.vph['ssl_verify'] = true if Settings.vph['ssl_verify'].nil?

  Settings['sidekiq'] ||= Settingslogic.new({})
  Settings.sidekiq['url'] ||= "redis://localhost:6379"
  Settings.sidekiq['namespace'] ||= "air"

  Settings['optimizer'] ||= Settings.new({})
  Settings.optimizer['max_appl_no'] ||= 5

  Settings['token_authentication_key'] ||= 'private_token'
  Settings['mi_authentication_key']    ||= 'mi_ticket'

  # Default config values for MetadataRegistry setup
  Settings['metadata'] ||= Settingslogic.new({})
  Settings.metadata['registry_endpoint'] = 'http://vphshare.atosresearch.eu/metadata-extended/rest/metadata/' if Settings.metadata['registry_endpoint'].nil?
  Settings.metadata['remote_connect'] = false if Settings.metadata['remote_connect'].nil?
  Settings.metadata['remote_publish'] = false if Settings.metadata['remote_publish'].nil?

  Settings['skip_pdp_for_admin'] = false if Settings['skip_pdp_for_admin'].nil?

  Settings['childhood_age'] ||= 2 # seconds
  Settings['cloud_object_protection_time'] = 300 # seconds
  Settings['cloud_client_cache_time'] = 8 #hours

  Settings['url_check'] ||= Settings.new({})
  Settings.url_check['unavail_statuses'] = [502]

end