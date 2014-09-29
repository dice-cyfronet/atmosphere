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

class Endpoint < ActiveRecord::Base
  extend Enumerize
  include EscapeXml

  belongs_to :port_mapping_template

  enumerize :endpoint_type, in: [:ws, :rest, :webapp]
  validates :endpoint_type, inclusion: %w(ws rest webapp)

  validates_presence_of :port_mapping_template, :invocation_path, :name

  before_validation :strip_invocation_path
  around_update :manage_metadata
  after_destroy :update_appliance_metadata, if: 'port_mapping_template.appliance_type and port_mapping_template.appliance_type.publishable?'
  after_create :update_appliance_metadata, if: 'port_mapping_template.appliance_type and port_mapping_template.appliance_type.publishable?'

  scope :def_order, -> { order(:description) }

  scope :at_endpoint, ->(at, service_name, invocation_path) { joins(:port_mapping_template).where(invocation_path: invocation_path, port_mapping_templates: {service_name: service_name, appliance_type_id: at.id}) }

  scope :appl_endpoints, ->(appl) { joins(port_mapping_template: :http_mappings).where(http_mappings: {appliance_id: appl.id}).uniq }

  scope :visible_to, ->(user) { EndpointsVisibleToUser.new(self, user).find }


  # This method is used to produce XML document that is being sent to the Metadata Registry
  def as_metadata_xml
    <<-MD_XML.strip_heredoc
      <endpoint>
        <endpointID>#{id}</endpointID>
        <name>#{esc_xml name}</name>
        <description>#{esc_xml description}</description>
      </endpoint>
    MD_XML
  end


  private

  def strip_invocation_path
    self.invocation_path.strip! if self.invocation_path
  end

  # METADATA lifecycle methods

  # Check if we need to update metadata regarding this endpoint's AT, if so, perform the task
  def manage_metadata
    old_pmt = port_mapping_template_id_changed? ? PortMappingTemplate.find(port_mapping_template_id_was) : nil
    yield
    port_mapping_template.appliance_type.update_metadata if port_mapping_template.appliance_type and port_mapping_template.appliance_type.publishable?
    if old_pmt and old_pmt.appliance_type and (old_pmt.appliance_type != port_mapping_template.appliance_type) and old_pmt.appliance_type.publishable?
      old_pmt.appliance_type.update_metadata
    end
  end

  def update_appliance_metadata
    port_mapping_template.appliance_type.update_metadata
  end
end
