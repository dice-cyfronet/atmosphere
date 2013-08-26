class PortMappingProperty < ActiveRecord::Base

  belongs_to :port_mapping_template
  belongs_to :compute_site

  validates_presence_of :key, :value

  validates_presence_of :port_mapping_template, if: 'compute_site == nil'
  validates_presence_of :compute_site, if: 'port_mapping_template == nil'

  validates_absence_of :port_mapping_template, if: 'compute_site != nil'
  validates_absence_of :compute_site, if: 'port_mapping_template != nil'

end
