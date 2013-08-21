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
