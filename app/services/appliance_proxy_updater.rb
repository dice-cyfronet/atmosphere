require 'uri'

class ApplianceProxyUpdater
  attr_reader :appliance

  def initialize(appliance)
    @appliance = appliance
  end

  def update(hints = {})
    pmt = affected_pmt(hints)
    old_pmt = old_pmt(hints)
    Updater.new(appliance, pmt, old_pmt).update if should_react?(hints)
  end

  private

  def should_react?(hints)
    # when PMT is destroyed than cascade is triggered to remove
    # http mappings
    #
    # TODO: Thinks about moving sidekiq logic here from http mappings
    # - pros: proxy logic in one place
    # - cons: since updater is invoked after successful PMT destroy
    #         all assigned http_mappings are removed
    #
    !hints[:destroyed] || hints[:destroyed].is_a?(PortMappingProperty)
  end

  def affected_pmt(hints)
    pmt = hints[:saved] || hints[:updated] || hints[:destroyed]
    pmt = pmt.port_mapping_template if pmt.is_a?(PortMappingProperty)
    pmt
  end

  def old_pmt(hints)
    hints[:old] if hints[:old] && hints[:old].is_a?(PortMappingTemplate)
  end

  class Updater
    def initialize(appliance, pmt, old_pmt)
      @appliance = appliance
      @port_mapping_templates = [pmt] if pmt
      @old_pmt = old_pmt
    end

    def update
      create_or_update? ? create_or_update_http_mappings : remove_http_mappings
    end

    private

    attr_reader :appliance

    def create_or_update_http_mappings
      to_update, to_remove = [], []
      port_mapping_templates.each do |pmt|
        to_update << update_for_pmt(pmt, 'http') if pmt.http?
        to_update << update_for_pmt(pmt, 'https') if pmt.https?

        if remove_old_mappings?(pmt, @old_pmt)
          to_remove << @old_pmt
        end
      end

      if appliance.save
        update_mappings(to_update)
        remove_proxy_for_pmts(to_remove)
      else
        Rails.logger.error "Cannot create http mappings for #{appliance.id} because of #{appliance.errors.to_json}"
      end
    end

    def update_mappings(mappings)
      mappings.each do |mapping|
        mapping.update_proxy(workers_ips)
      end
    end

    def remove_proxy_for_pmts(pmts)
      pmts.each do |pmt|
        remove_proxy(pmt, 'http') if pmt.http?
        remove_proxy(pmt, 'https') if pmt.https?
      end
    end

    def remove_http_mappings
      appliance.http_mappings.destroy_all
    end

    def port_mapping_templates
      @port_mapping_templates || appliance_port_mapping_templates
    end

    def appliance_port_mapping_templates
      appliance.development? ? appliance.dev_mode_property_set.port_mapping_templates : appliance.appliance_type.port_mapping_templates
    end

    def mapping(pmt, type)
      appliance.http_mappings.find_or_initialize_by(port_mapping_template_id: pmt.id, application_protocol: type)
    end

    def main_compute_site
      @main_cs ||= ComputeSite.with_appliance(appliance).first
    end

    def update_for_pmt(pmt, type)
      http_mapping = mapping(pmt, type)
      http_mapping.compute_site ||= main_compute_site
      http_mapping.url = url(http_mapping, base_url(type)) if http_mapping.url.blank?
      http_mapping
    end

    def base_url(type)
      type == 'http' ? main_compute_site.http_proxy_url : main_compute_site.https_proxy_url
    end

    def url(http_mapping, base_url)
      uri = URI(base_url)
      "#{uri.scheme}://#{http_mapping.proxy_name}.#{uri.host}"
    end

    def create_or_update?
      !workers_ips.blank?
    end

    def workers_ips
      @workers_ips ||= appliance.active_vms.pluck(:ip)
    end

    def remove_old_mappings?(pmt, old_pmt)
      old_pmt && pmt.id == old_pmt.id && pmt.service_name != old_pmt.service_name
    end

    def remove_proxy(pmt, type)
      Sidekiq::Client.push(
        'queue' => mapping(pmt, type).compute_site.site_id,
        'class' => Redirus::Worker::RmProxy,
        'args' => ["#{pmt.service_name}.#{appliance.id}", type])
    end
  end
end