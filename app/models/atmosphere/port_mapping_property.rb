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
module Atmosphere
  class PortMappingProperty < ActiveRecord::Base
    belongs_to :port_mapping_template,
      class_name: 'Atmosphere::PortMappingTemplate'

    belongs_to :tenant,
      class_name: 'Atmosphere::Tenant'

    validates :key,
              presence: true,
              uniqueness: { scope: :port_mapping_template_id }

    validates :value,
              presence: true

    validates :port_mapping_template,
              presence: true,
              if: 'tenant == nil'
    validates :port_mapping_template,
              absence: true,
              if: 'tenant != nil'

    validates :tenant,
              presence: true,
              if: 'port_mapping_template == nil'
    validates :tenant,
              absence: true,
              if: 'port_mapping_template != nil'

    def to_s
      "#{key} #{value}"
    end
  end
end
