

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
      class_name: 'Atmosphere::VirtualMachine'

    has_many :os_families,
      through: :virtual_machine_flavor_os_families,
      class_name: 'Atmosphere::OSFamily'

    has_many :virtual_machine_flavor_os_families,
      class_name: 'Atmosphere::VirtualMachineFlavorOSFamily'

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
      incarnation = virtual_machine_flavor_os_families.select{|vmf_osf| vmf_osf.os_family == os_family}.first
      if incarnation.is_a?(Atmosphere::VirtualMachineFlavorOSFamily)
        incarnation.hourly_cost
      else
        nil #GIGO
      end
    end

    # Upserts a binding between this VMF and an OS family, setting hourly cost
    def set_hourly_cost_for(os_family, cost)
      incarnation = virtual_machine_flavor_os_families.select{|vmf_osf| vmf_osf.os_family == os_family}.first
      if incarnation.is_a?(Atmosphere::VirtualMachineFlavorOSFamily)
        incarnation.hourly_cost = cost
        incarnation.save
      else
        incarnation = Atmosphere::VirtualMachineFlavorOSFamily.new(virtual_machine_flavor: self, os_family: os_family,
          hourly_cost: cost)
        incarnation.save
      end
    end

    # Provides backward compatibility with old versions of the GUI
    def hourly_cost
      if virtual_machine_flavor_os_families.blank?
        nil
      else
        virtual_machine_flavor_os_families.max_by(&:hourly_cost).hourly_cost
      end
    end

    # Returns a full cost map for this flavor (depending on os_family)
    def cost_map
      result = {}
      virtual_machine_flavor_os_families.each do |f|
        result[f.os_family.os_family_name] = f.hourly_cost
      end
      result
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
