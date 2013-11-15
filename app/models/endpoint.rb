# == Schema Information
#
# Table name: endpoints
#
#  id                       :integer          not null, primary key
#  description              :text
#  descriptor               :text(16777215)
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

  validates_presence_of :port_mapping_template, :invocation_path

  scope :def_order, -> { order(:description) }

end
