# == Schema Information
#
# Table name: port_mapping_properties
#
#  id                       :integer          not null, primary key
#  key                      :string(255)      not null
#  value                    :string(255)      not null
#  port_mapping_template_id :integer
#  compute_site_id          :integer
#  created_at               :datetime
#  updated_at               :datetime
#

class PortMappingProperty < ActiveRecord::Base

  belongs_to :port_mapping_template
  belongs_to :compute_site

  validates_presence_of :key, :value

  validates_presence_of :port_mapping_template, if: 'compute_site == nil'
  validates_presence_of :compute_site, if: 'port_mapping_template == nil'

  validates_absence_of :port_mapping_template, if: 'compute_site != nil'
  validates_absence_of :compute_site, if: 'port_mapping_template != nil'

  validates_uniqueness_of :key, :scope => :port_mapping_template_id

  after_save :generate_proxy_conf
  after_destroy :generate_proxy_conf

  def to_s
    "#{key} #{value}"
  end

  private

  def generate_proxy_conf
    port_mapping_template.blank? ? ProxyConfWorker.regeneration_required(compute_site) : port_mapping_template.generate_proxy_conf
  end
end
