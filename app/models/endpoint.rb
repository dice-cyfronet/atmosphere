class Endpoint < ActiveRecord::Base
  extend Enumerize

  belongs_to :port_mapping_template

  enumerize :endpoint_type, in: [:ws, :rest, :webapp]
  validates :endpoint_type, inclusion: %w(ws rest webapp)

  validates_presence_of :port_mapping_template

end
