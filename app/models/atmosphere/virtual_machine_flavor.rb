

# == Schema Information
#
# Table name: virtual_machine_flavors
#
#  id                      :integer          not null, primary key
#  flavor_name             :string(255)      not null
#  cpu                     :float
#  memory                  :float
#  hdd                     :float
#  hourly_cost             :integer          not null
#  compute_site_id         :integer
#  id_at_site              :string(255)
#  supported_architectures :string(255)      default("x86_64")
#

# VirtualMachineFlavor
# Added by PN on 2014-01-14
# This class stores information on the VM flavors available at each compute site registered with AIR
# For each flavor, the associated hourly cost is defined.
module Atmosphere
  class VirtualMachineFlavor < ActiveRecord::Base
    belongs_to :compute_site,
      class_name: 'Atmosphere::ComputeSite'

    has_many :virtual_machines,
      class_name: 'Atmosphere::VirtualMachine',
      dependent: :restrict_with_error

    has_many :os_families,
      through: :flavor_os_families,
      class_name: 'Atmosphere::OSFamily'

    has_many :flavor_os_families,
      inverse_of: :virtual_machine_flavor,
      class_name: 'Atmosphere::FlavorOSFamily',
      autosave: true,
      dependent: :destroy

    validates :flavor_name,
              presence: true

    validates :cpu,
              numericality: { greater_than_or_equal_to: 0 }

    validates :memory,
              numericality: { greater_than_or_equal_to: 0 }

    validates :hdd,
              numericality: { greater_than_or_equal_to: 0 }

    validates :supported_architectures,
              inclusion: %w(i386 x86_64 i386_and_x86_64)

    scope :with_prefs, ->(options) do
      FlavorsWithRequirements.new(self, options).find
    end

    scope :with_arch, ->(arch) do
      where(supported_architectures: ['i386_and_x86_64', arch])
    end

    scope :on_cs, ->(cs) do
      cs_id = cs.respond_to?(:id) ? cs.id : cs
      where(compute_site_id: cs_id)
    end

    scope :active, -> { where(active: true) }

    # Assumes only 1 vmf_osf for a specific os_family
    def get_hourly_cost_for(os_family)
      incarnation = flavor_os_families.find_by(os_family: os_family)
      incarnation && incarnation.hourly_cost # nil if incarnation.blank?
    end

    # Upserts a binding between this VMF and an OS family, setting hourly cost
    def set_hourly_cost_for(os_family, cost)
      incarnation = flavor_os_families.
          find_or_initialize_by(os_family: os_family)
      incarnation.hourly_cost = cost
      incarnation.save
    end

    # Makes a flavor unavailable for a given OSFamily
    def remove_hourly_cost_for(os_family)
      incarnation = flavor_os_families.find_by(os_family: os_family)
      incarnation && incarnation.destroy # nil if incarnation.blank?
    end

    # Provides backward compatibility with old versions of the GUI
    def hourly_cost
      flavor_os_families &&
        flavor_os_families.maximum(:hourly_cost)
    end

    # Returns a full cost map for this flavor (depending on os_family)
    def cost_map
      flavor_os_families.each_with_object({}) do |f, hash|
        hash[f.os_family.name] = f.hourly_cost
      end
    end

    def usable?
      active && compute_site && compute_site.active
    end

    def supports_architecture?(arch)
      supported_architectures == 'i386_and_x86_64' ||
          supported_architectures == arch
    end
  end
end
