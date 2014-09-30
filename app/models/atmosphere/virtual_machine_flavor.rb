

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
    self.table_name = 'virtual_machine_flavors'

    belongs_to :compute_site,
      class_name: 'Atmosphere::ComputeSite'

    has_many :virtual_machines,
      class_name: 'Atmosphere::VirtualMachine'

    validates_presence_of :flavor_name
    validates_numericality_of :cpu, greater_than_or_equal_to: 0
    validates_numericality_of :memory, greater_than_or_equal_to: 0
    validates_numericality_of :hdd, greater_than_or_equal_to: 0
    validates_numericality_of :hourly_cost, greater_than_or_equal_to: 0
    validates :supported_architectures, inclusion: %w(i386 x86_64 i386_and_x86_64)

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

    def usable?
      active && compute_site && compute_site.active
    end

    def supports_architecture?(arch)
      supported_architectures == 'i386_and_x86_64' ||
          supported_architectures == arch
    end
  end
end
