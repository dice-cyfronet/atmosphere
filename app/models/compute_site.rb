# == Schema Information
#
# Table name: compute_sites
#
#  id              :integer          not null, primary key
#  site_id         :string(255)      not null
#  name            :string(255)
#  location        :string(255)
#  site_type       :string(255)      default("private")
#  technology      :string(255)
#  username        :string(255)
#  api_key         :string(255)
#  auth_method     :string(255)
#  auth_url        :string(255)
#  authtenant_name :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class ComputeSite < ActiveRecord::Base
  extend Enumerize

  validates_presence_of :site_id, :site_type, :technology
  enumerize :site_type, in: [:public, :private], predicates: true
  enumerize :technology, in: [:openstack, :aws], predicates: true
  validates :site_type, inclusion: %w(public private)
  validates :technology, inclusion: %w(openstack aws)

  has_many :virtual_machines, dependent: :destroy
  has_many :virtual_machine_templates, dependent: :destroy
  has_many :port_mapping_properties, dependent: :destroy

  def to_s
    name
  end

  def cloud_client
    Air.cloud_clients[self.site_id] || register_cloud_client
  end

  private
  def register_cloud_client
    cloud_site_conf = JSON.parse(self.config).symbolize_keys
    client = Fog::Compute.new(cloud_site_conf)
    Air.cloud_clients[self.site_id] = client
    client
  end

end
