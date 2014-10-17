class Settings < Settingslogic
  source "#{Rails.root}/config/air.yml"
  namespace Rails.env

  Settings['sidekiq'] ||= Settingslogic.new({})
  Settings.sidekiq['url'] ||= "redis://localhost:6379"
  Settings.sidekiq['namespace'] ||= "air"

  Settings['optimizer'] ||= Settings.new({})
  Settings.optimizer['max_appl_no'] ||= 5

  Settings['childhood_age'] ||= 2 # seconds
  Settings['cloud_object_protection_time'] ||= 300 # seconds
  Settings['cloud_client_cache_time'] ||= 8 #hours
  Settings['vmt_at_relation_update_period'] ||= 2 # hours

  Settings['url_check'] ||= Settings.new({})
  Settings.url_check['unavail_statuses'] ||= [502]

  Settings['monitoring'] ||= Settingslogic.new({})
  Settings.monitoring['query_interval'] ||= 5

  Settings['http_mapping_monitor'] ||= Settingslogic.new({})
  Settings.http_mapping_monitor['pending'] ||= 10
  Settings.http_mapping_monitor['ok'] ||= 120
  Settings.http_mapping_monitor['lost'] ||= 15

  #vph spedific
  class << self
    def header_mi_authentication_key
      to_header_key(mi_authentication_key)
    end

    private

    def to_header_key(key)
      key.upcase.gsub(/_/, '-')
    end
  end

  Settings['skip_pdp_for_admin'] = false if Settings['skip_pdp_for_admin'].nil?

  # Default config values for MetadataRegistry setup
  Settings['metadata'] ||= Settingslogic.new({})
  Settings.metadata['registry_endpoint'] = 'http://vphshare.atosresearch.eu/metadata-extended/rest/metadata/' if Settings.metadata['registry_endpoint'].nil?
  Settings.metadata['remote_connect'] = false if Settings.metadata['remote_connect'].nil?
  Settings.metadata['remote_publish'] = false if Settings.metadata['remote_publish'].nil?

  Settings['mi_authentication_key']    ||= 'mi_ticket'

  Settings['vph'] ||= Settingslogic.new({})
  Settings.vph['enabled'] = false if Settings.vph['enabled'].nil?
  Settings.vph['ssl_verify'] = true if Settings.vph['ssl_verify'].nil?
end