# == Schema Information
#
# Table name: http_mappings
#
#  id                       :integer          not null, primary key
#  application_protocol     :string(255)      default("http"), not null
#  url                      :string(255)      default(""), not null
#  appliance_id             :integer
#  port_mapping_template_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#  compute_site_id          :integer          not null
#  monitoring_status        :string(255)      default("pending")
#
module Atmosphere
  class HttpMapping < ActiveRecord::Base
    extend Enumerize
    include Slugable

    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :port_mapping_template,
      class_name: 'Atmosphere::PortMappingTemplate'

    belongs_to :tenant,
      class_name: 'Atmosphere::Tenant'

    validates :url,
              presence: true

    validates :application_protocol,
              presence: true,
              inclusion: { in: %w(http https) }

    validates :appliance,
              presence: true

    validates :port_mapping_template,
              presence: true

    validates :tenant,
              presence: true

    validates :custom_name,
              uniqueness: {
                scope: [:tenant_id, :application_protocol],
                allow_blank: true
              }

    enumerize :application_protocol,
              in: [:http, :https]

    enumerize :monitoring_status,
              in: [:pending, :ok, :lost, :not_monitored]

    before_save :slug_custom_name
    around_destroy :rm_proxy_after_destroy
    around_save :update_custom_proxy

    def update_proxy(ips = nil)
      create_or_update_proxy(ips) || rm_proxies
    end

    def proxy_name
      "#{service_name}-#{appliance_id}"
    end

    def create_or_update_proxy(ips = nil)
      if has_workers?(ips)
        add_proxy(proxy_name, ips)
        add_proxy(custom_name, ips) if custom_name

        true
      end
    end

    def custom_url
      unless custom_name.blank?
        Proxy::UrlGenerator.glue(base_url, custom_name)
      end
    end

    private

    def workers(ips=nil)
      (ips || workers_ips).collect { |ip| "#{ip}:#{target_port}" }
    end

    delegate :service_name, :target_port, :properties, to: :port_mapping_template
    delegate :active_vms, to: :appliance

    def rm_proxies(default_proxy_name = proxy_name)
      rm_proxy(default_proxy_name)
      rm_proxy(custom_name) if custom_name
    end

    def rm_proxy(name)
      Sidekiq::Client.push('queue' => tenant.tenant_id, 'class' => Redirus::Worker::RmProxy, 'args' => [name, application_protocol])
    end

    def add_proxy(name, ips=nil)
      Sidekiq::Client.push('queue' => tenant.tenant_id, 'class' => Redirus::Worker::AddProxy, 'args' => [name, workers(ips), application_protocol, properties])
    end

    def has_workers?(ips)
      ips && ips.size > 0 || workers_ips.size > 0
    end

    def workers_ips
      @workers_ips ||= active_vms.pluck(:ip)
    end

    def rm_proxy_after_destroy
      p_name = proxy_name
      yield
      rm_proxies(p_name)
    end

    def update_custom_proxy
      old_custom_name = custom_name_was

      yield

      if old_custom_name != custom_name
        rm_proxy(old_custom_name) unless old_custom_name.blank?
        add_proxy(custom_name) unless custom_name.blank?
      end
    end

    def slug_custom_name
      self.custom_name = to_slug(self.custom_name) if self.custom_name
    end
  end
end
