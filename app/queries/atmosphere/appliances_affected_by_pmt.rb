#
# Find all appliances affected by given port mapping template.
#
module Atmosphere
  class AppliancesAffectedByPmt
    def initialize(pmt)
      @pmt = pmt
    end

    def find
      joined_appliance.where(
          port_mapping_templates: { id: @pmt.id }
        ).readonly(false)
    end

    private

    def joined_appliance
      if prod_mode?
        Appliance.joins(appliance_type: :port_mapping_templates)
      else
        Appliance.joins(dev_mode_property_set: :port_mapping_templates)
      end
    end

    def prod_mode?
      @pmt.dev_mode_property_set.blank?
    end
  end
end