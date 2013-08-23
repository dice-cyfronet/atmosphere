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

  validates_presence_of :url, :application_protocol
  validates_inclusion_of :application_protocol, in: %w(http https)
  enumerize :application_protocol, in: [:http, :https]

  belongs_to :appliance
  validates :appliance, presence: true

  belongs_to :port_mapping_template
  validates :port_mapping_template, presence: true
end
