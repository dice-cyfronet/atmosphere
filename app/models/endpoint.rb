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
#

class Endpoint < ActiveRecord::Base
  extend Enumerize
  include EscapeXml

  belongs_to :port_mapping_template

  enumerize :endpoint_type, in: [:ws, :rest, :webapp]
  validates :endpoint_type, inclusion: %w(ws rest webapp)

  validates_presence_of :port_mapping_template, :invocation_path, :name

  before_validation :strip_invocation_path

  scope :def_order, -> { order(:description) }

  scope :at_endpoint, ->(at, service_name, invocation_path) { joins(:port_mapping_template).where(invocation_path: invocation_path, port_mapping_templates: {service_name: service_name, appliance_type_id: at.id}) }

  scope :appl_endpoints, ->(appl) { joins(port_mapping_template: :http_mappings).where(http_mappings: {appliance_id: appl.id}).uniq }

  scope :visible_to, ->(user) { includes(port_mapping_template: { appliance_type: {}, dev_mode_property_set: { appliance: :appliance_set } }).where("appliance_types.visible_to = 'all' or appliance_types.user_id = :user_id or appliance_sets.user_id = :user_id", { user_id: user.id }).references(:appliance_types, :appliance_sets) }


  # This method is used to produce XML document that is being sent to the Metadata Registry
  def as_metadata_xml
    <<-MD_XML.strip_heredoc
      <Endpoint>
        <endpointID>#{id}</endpointID>
        <endpointName>#{esc_xml name}</endpointName>
        <endpointDescription>#{esc_xml description}</endpointDescription>
      </Endpoint>
    MD_XML
  end


  private

  def strip_invocation_path
    self.invocation_path.strip! if self.invocation_path
  end
end
