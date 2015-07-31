# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  description              :text
#  descriptor               :text
#  endpoint_type            :string(255)      default("ws"), not null
#  invocation_path          :string(255)      not null
#  port_mapping_template_id :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#  secured                  :boolean          default(FALSE), not null
#
module Atmosphere
  class Endpoint < ActiveRecord::Base
    include Atmosphere::EndpointExt
    extend Enumerize

    belongs_to :port_mapping_template,
               class_name: 'Atmosphere::PortMappingTemplate'

    validates :endpoint_type,
              inclusion: %w(ws rest webapp)

    validates :port_mapping_template,
              presence: true

    validates :invocation_path,
              presence: true

    validates :name,
              presence: true

    enumerize :endpoint_type, in: [:ws, :rest, :webapp]

    scope :def_order, -> { order(:description) }

    scope :at_endpoint, ->(at, service_name, invocation_path) do
      joins(:port_mapping_template).
        where(
          invocation_path: invocation_path,
          atmosphere_port_mapping_templates: {
            service_name: service_name,
            appliance_type_id: at.id
          }
        )
    end

    scope :appl_endpoints, ->(appl) do
      joins(port_mapping_template: :http_mappings).
        where(
          atmosphere_http_mappings: {
            appliance_id: appl.id
          }
        ).uniq
    end

    scope :visible_to, ->(user) { EndpointsVisibleToUser.new(self, user).find }

    before_validation :strip_invocation_path

    private

    def strip_invocation_path
      invocation_path.strip! if invocation_path
    end
  end
end
