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
  has_one :compute_site

  validates_presence_of :url, :application_protocol, :appliance, :port_mapping_template, :compute_site

  validates_inclusion_of :application_protocol, in: %w(http https)
  enumerize :application_protocol, in: [:http, :https]

  after_destroy :rm_proxy

  def update_proxy
    create_update_proxy || rm_proxy
  end

  private

  delegate :service_name, :target_port, :properties, to: :port_mapping_template
  delegate :active_vms, to: :appliance

  def create_update_proxy
    has_workers? && Redirus::Worker::AddProxy.perform_async(proxy_name, workers, application_protocol, properties)
  end

  def rm_proxy
    Redirus::Worker::RmProxy.perform_async(proxy_name, application_protocol)
  end

  def proxy_name
    "#{service_name}.#{appliance.id}"
  end

  def has_workers?
    workers_ips.size > 0
  end

  def workers
    workers_ips.collect { |ip| "#{ip}:#{target_port}" }
  end

  def workers_ips
    @workers_ips ||= active_vms.pluck(:ip)
  end
end
