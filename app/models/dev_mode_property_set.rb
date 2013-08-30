class DevModePropertySet < ActiveRecord::Base
  validates_presence_of :name

  validates :shared, inclusion: [true, false]
  validates :scalable, inclusion: [true, false]

  validates :preference_memory, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_disk, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_cpu, numericality: { greater_than_or_equal_to: 0.0, allow_nil: true }

  belongs_to :security_proxy

  belongs_to :appliance
  validates_presence_of :appliance

  has_many :port_mapping_templates, dependent: :destroy

  def self.create_from(appliance_type)
    dev_mode_property_set = DevModePropertySet.new(
      name: appliance_type.name,
      description: appliance_type.description,
      shared: appliance_type.shared,
      scalable: appliance_type.scalable,
      preference_cpu: appliance_type.preference_cpu,
      preference_memory: appliance_type.preference_memory,
      preference_disk: appliance_type.preference_disk,
      security_proxy: appliance_type.security_proxy,
    )

    dev_mode_property_set.port_mapping_templates = appliance_type.port_mapping_templates.collect do |pmt|
        copy = pmt.dup
        copy.endpoints = pmt.endpoints.collect(&:dup)
        copy.port_mapping_properties = pmt.port_mapping_properties.collect(&:dup)
        copy
      end

    dev_mode_property_set
  end
end
