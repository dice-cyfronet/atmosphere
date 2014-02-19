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
#

class HttpMapping < ActiveRecord::Base
  extend Enumerize

  belongs_to :appliance
  belongs_to :port_mapping_template
  belongs_to :compute_site

  validates_presence_of :url, :application_protocol, :appliance, :port_mapping_template, :compute_site

  validates_inclusion_of :application_protocol, in: %w(http https)
  enumerize :application_protocol, in: [:http, :https]

  after_destroy :rm_proxy

  def update_proxy(ips = nil)
    create_or_update_proxy(ips) || rm_proxy
  end

  def proxy_name
    "#{service_name}.#{appliance.id}"
  end

  def create_or_update_proxy(ips = nil)
    if has_workers?(ips)
      Sidekiq::Client.push('queue' => compute_site.site_id, 'class' => Redirus::Worker::AddProxy, 'args' => [proxy_name, workers(ips), application_protocol, properties])
      true
    end
  end

  private

  def workers(ips=nil)
    (ips || workers_ips).collect { |ip| "#{ip}:#{target_port}" }
  end

  delegate :service_name, :target_port, :properties, to: :port_mapping_template
  delegate :active_vms, to: :appliance

  def rm_proxy
    Sidekiq::Client.push('queue' => compute_site.site_id, 'class' => Redirus::Worker::RmProxy, 'args' => [proxy_name, application_protocol])
  end

  def has_workers?(ips)
    ips && ips.size > 0 || workers_ips.size > 0
  end

  def workers_ips
    @workers_ips ||= active_vms.pluck(:ip)
  end
end
