require 'uri'

class ApplianceProxyUpdater
  attr_reader :appliance

  def initialize(appliance, options = {})
    @appliance = appliance
    @port_mapping_templates = options[:port_mapping_templates]
  end

  def update
    main_compute_site ? create_or_update_http_mappings : remove_http_mappings
  end

  private

  def create_or_update_http_mappings
    port_mapping_templates.each do |pmt|
      update_for_pmt(pmt, 'http') if pmt.http?
      update_for_pmt(pmt, 'https') if pmt.https?
    end

    if appliance.save
      appliance.http_mappings.each do |mapping|
        mapping.update_proxy(workers_ips)
      end
    else
      Rails.logger.error "Cannot create http mappings for #{appliance.id} because of #{appliance.errors.to_json}"
    end
  end

  def remove_http_mappings
    appliance.http_mappings.destroy_all
  end

  def port_mapping_templates
    @port_mapping_templates || appliance.appliance_type.port_mapping_templates
  end

  def mapping(pmt, type)
    appliance.http_mappings.find_or_initialize_by(port_mapping_template: pmt, application_protocol: type)
  end

  def main_compute_site
    @main_cs ||= ComputeSite.with_appliance(appliance).first
  end

  def update_for_pmt(pmt, type)
    http_mapping = mapping(pmt, type)
    http_mapping.compute_site ||= main_compute_site
    http_mapping.url = url(http_mapping, base_url(type)) if http_mapping.url.blank?
  end

  def base_url(type)
    type == 'http' ? main_compute_site.http_proxy_url : main_compute_site.https_proxy_url
  end

  def url(http_mapping, base_url)
    uri = URI(base_url)
    "#{uri.scheme}://#{http_mapping.proxy_name}.#{uri.host}"
  end

  def workers_ips
    @workers_ips ||= appliance.active_vms.pluck(:ip)
  end
end