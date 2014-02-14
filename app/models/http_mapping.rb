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

  validates_presence_of :url, :application_protocol, :appliance, :port_mapping_template

  validates_inclusion_of :application_protocol, in: %w(http https)
  enumerize :application_protocol, in: [:http, :https]

  after_destroy :rm_proxy

  def update_proxy
    Redirus::Worker::AddProxy.perform_async(port_mapping_template.service_name, workers, application_protocol, properties) if has_workers?
  end

  private

  def rm_proxy
    Redirus::Worker::RmProxy.perform_async(port_mapping_template.service_name, application_protocol)
  end

  def has_workers?
    workers.size > 0
  end

  def workers
    unless @workers
      target_port = port_mapping_template.target_port
      @workers = active_workers_ips.collect { |ip| "#{ip}:#{target_port}" }
    end
    @workers
  end

  def active_workers_ips
    appliance.virtual_machines.active.pluck(:ip)
  end

  def properties
    port_mapping_template.port_mapping_properties.collect { |pmp| pmp.to_s }
  end
end
