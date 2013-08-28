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
end
