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
#  active            :boolean          default(TRUE)
#
module Atmosphere
  class ComputeSite < ActiveRecord::Base
    extend Enumerize

    has_many :virtual_machines,
      dependent: :destroy,
      class_name: 'Atmosphere::VirtualMachine'

    has_many :virtual_machine_templates,
      dependent: :destroy,
      class_name: 'Atmosphere::VirtualMachineTemplate'

    has_many :port_mapping_properties,
      dependent: :destroy,
      class_name: 'Atmosphere::PortMappingProperty'

    has_many :virtual_machine_flavors,
      dependent: :destroy,
      class_name: 'Atmosphere::VirtualMachineFlavor'

    # Required for API (returning all compute sites on which a given AT can be deployed)
    has_many :appliance_types,
      through: :virtual_machine_templates,
      class_name: 'Atmosphere::ApplianceType'

    has_many :funds,
      through: :compute_site_funds,
      class_name: 'Atmosphere::Fund'

    has_many :compute_site_funds,
      dependent: :destroy,
      class_name: 'Atmosphere::ComputeSiteFund'

    has_many :appliances,
      through: :appliance_compute_sites,
      class_name: 'Atmosphere::Appliance'

    has_many :appliance_compute_sites,
      dependent: :destroy,
      class_name: 'Atmosphere::ApplianceComputeSite'

    has_many :migration_job,
      dependent: :destroy,
      class_name: 'Atmosphere::MigrationJob'

    validates :site_id, presence: true

    validates :site_type,
              presence: true,
              inclusion: %w(public private)

    validates :technology,
              presence: true,
              inclusion: %w(openstack aws)

    enumerize :site_type, in: [:public, :private], predicates: true
    enumerize :technology, in: [:openstack, :aws], predicates: true

    scope :with_appliance_type, ->(appliance_type) do
      joins(virtual_machines: {appliances: :appliance_set})
        .where(
          atmosphere_appliances: {
            appliance_type_id: appliance_type
          },
          atmosphere_appliance_sets: {
            appliance_set_type: [:workflow, :portal]
          }
        ).readonly(false)
    end

    scope :with_deployment, ->(deployment) do
      joins(virtual_machines: :deployments)
        .where(
          deployments: {
            id: deployment.id
          }
        ).readonly(false)
    end

    scope :with_dev_property_set, ->(dev_mode_property_set) do
      joins(virtual_machines: { appliances: :dev_mode_property_set })
        .where(
          atmosphere_dev_mode_property_sets: {
            id: dev_mode_property_set.id
          }
        ).readonly(false)
    end

    scope :with_appliance, ->(appliance) do
      joins(virtual_machines: :appliances)
        .where(atmosphere_appliances: {id: appliance.id})
    end

    scope :active, -> { where(active: true) }

    after_update :update_cloud_client, if: :config_changed?
    after_destroy :unregister_cloud_client

    def to_s
      name
    end

    def cloud_client
      Atmosphere.get_cloud_client(self.site_id) || register_cloud_client
    end

    def dnat_client
      DnatWrangler.new(wrangler_url, wrangler_username, wrangler_password)
    end

    def proxy_urls_changed?
      previously_changed?('http_proxy_url', 'https_proxy_url')
    end

    def site_id_previously_changed?
      previously_changed?('site_id')
    end

    def default_flavor
      virtual_machine_flavors.first
    end

    private

    def update_cloud_client
      unless config.blank?
        register_cloud_client
      else
        unregister_cloud_client
      end
    end

    def register_cloud_client
      cloud_site_conf = JSON.parse(self.config).symbolize_keys
      client = Fog::Compute.new(cloud_site_conf)
      Atmosphere.register_cloud_client(self.site_id, client)
      client
    end

    def unregister_cloud_client
      Atmosphere.unregister_cloud_client(site_id)
    end

    def previously_changed?(*args)
      !(previous_changes.keys & args).empty?
    end
  end
end
