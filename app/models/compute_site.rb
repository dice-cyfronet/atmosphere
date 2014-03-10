# == Schema Information
#
# Table name: compute_sites
#
#  id                :integer          not null, primary key
#  site_id           :string(255)      not null
#  name              :string(255)
#  location          :string(255)
#  site_type         :string(255)      default("private")
#  technology        :string(255)
#  http_proxy_url    :string(255)
#  https_proxy_url   :string(255)
#  config            :text
#  template_filters  :text
#  created_at        :datetime
#  updated_at        :datetime
#  wrangler_url      :string(255)
#  wrangler_username :string(255)
#  wrangler_password :string(255)
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
  has_many :virtual_machine_flavors, dependent: :destroy

  scope :with_appliance_type, ->(appliance_type) { joins(virtual_machines: {appliances: :appliance_set}).where(appliances: {appliance_type_id: appliance_type.id}, appliance_sets: {appliance_set_type: [:workflow, :portal]}).readonly(false) }

  scope :with_deployment, ->(deployment) { joins(virtual_machines: :deployments).where(deployments: {id: deployment.id}).readonly(false) }

  scope :with_dev_property_set, ->(dev_mode_property_set) { joins(virtual_machines: {appliances: :dev_mode_property_set}).where(dev_mode_property_sets: {id: dev_mode_property_set.id}).readonly(false) }

  scope :with_appliance, ->(appliance) {joins(virtual_machines: :appliances).where(appliances: {id: appliance.id})}

  after_update :update_cloud_client, if: :config_changed?
  after_destroy :unregister_cloud_client

  def to_s
    name
  end

  def cloud_client
    Air.get_cloud_client(self.site_id) || register_cloud_client
  end

  def dnat_client
    DnatWrangler.new(wrangler_url, wrangler_username, wrangler_password)
  end

  def proxy_urls_changed?
    changed_attrs = previous_changes.keys
    changed_attrs.include?('http_proxy_url') || changed_attrs.include?('https_proxy_url')
  end

  private
  def register_cloud_client
    cloud_site_conf = JSON.parse(self.config).symbolize_keys
    client = Fog::Compute.new(cloud_site_conf)
    Air.register_cloud_client(self.site_id, client)
    client
  end

  def update_cloud_client
    unless config.blank?
      register_cloud_client
    else
      unregister_cloud_client
    end
  end

  def unregister_cloud_client
    Air.unregister_cloud_client(site_id)
  end
end
