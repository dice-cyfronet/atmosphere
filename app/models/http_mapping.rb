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

end
