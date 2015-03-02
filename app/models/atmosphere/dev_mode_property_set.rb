# == Schema Information
#
# Table name: dev_mode_property_sets
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  description       :text
#  shared            :boolean          default(FALSE), not null
#  scalable          :boolean          default(FALSE), not null
#  preference_cpu    :float
#  preference_memory :integer
#  preference_disk   :integer
#  appliance_id      :integer          not null
#  security_proxy_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#
module Atmosphere
  class DevModePropertySet < ActiveRecord::Base
    include Atmosphere::DevModePropertySetExt

    belongs_to :appliance,
      class_name: 'Atmosphere::Appliance'

    belongs_to :os_family,
      class_name: 'Atmosphere::OSFamily'

      has_many :port_mapping_templates,
        dependent: :destroy,
        autosave: true,
        class_name: 'Atmosphere::PortMappingTemplate'

    validates :appliance,
              presence: true

    validates :name,
              presence: true

    validates :shared,
              inclusion: [true, false]

    validates :scalable,
              inclusion: [true, false]

    validates :preference_memory,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true
              }

    validates :preference_disk,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                allow_nil: true
              }

    validates :preference_cpu,
              numericality: {
                greater_than_or_equal_to: 0.0,
                allow_nil: true
              }

    def self.create_from(appliance_type)
      copy_params = ['name', 'description', 'shared',
        'scalable', 'preference_cpu', 'preference_memory',
        'preference_disk'] + copy_additional_params

      attrs = appliance_type.attributes.select do |k, _|
        copy_params.include? k
      end

      dev_mode_property_set = DevModePropertySet.new(attrs)
      dev_mode_property_set.port_mapping_templates =
        PmtCopier.copy(appliance_type).each  do |pmt|
          pmt.dev_mode_property_set = dev_mode_property_set
        end

      dev_mode_property_set.os_family = appliance_type.os_family

      dev_mode_property_set
    end
  end
end
