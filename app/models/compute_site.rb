# == Schema Information
#
# Table name: compute_sites
#
#  id         :integer          not null, primary key
#  site_id    :string(255)
#  name       :string(255)
#  location   :string(255)
#  site_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class ComputeSite < ActiveRecord::Base
  extend Enumerize

  validates_presence_of :site_id, :site_type
  enumerize :site_type, in: [:public, :private], predicates: true
  validates :site_type, inclusion: %w(public private)

  # openstack specific
  validates :auth_method, inclusion: %w(password key rax-kskey), :allow_nil => true
  
  validates :technology, inclusion: %w(openstack amazon)

  has_many :virtual_machines
  has_many :virtual_machine_templates
  has_many :port_mapping_properties
end
