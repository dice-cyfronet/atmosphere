# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  description              :text
#  descriptor               :text
#  endpoint_type            :string(255)      default("ws"), not null
#  port_mapping_template_id :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#

class Endpoint < ActiveRecord::Base
  extend Enumerize

  belongs_to :port_mapping_template

  enumerize :endpoint_type, in: [:ws, :rest, :webapp]
  validates :endpoint_type, inclusion: %w(ws rest webapp)

  validates_presence_of :port_mapping_template, :invocation_path, :name

  before_validation :strip_invocation_path

  scope :def_order, -> { order(:description) }

  scope :at_endpoint, ->(at, service_name, invocation_path) { joins(:port_mapping_template).where(invocation_path: invocation_path, port_mapping_templates: {service_name: service_name, appliance_type_id: at.id}) }

  scope :appl_endpoints, ->(appl) { joins(port_mapping_template: :http_mappings).where(http_mappings: {appliance_id: appl.id}).uniq }

  private

  def strip_invocation_path
    self.invocation_path.strip! if self.invocation_path
  end
end
