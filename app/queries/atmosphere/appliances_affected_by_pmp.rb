#
# Find all appliances affected by given port mapping property.
#
module Atmosphere
  class AppliancesAffectedByPmp
    def initialize(pmp)
      @pmp = pmp
    end

    def find
      joined_appliance.where(
          port_mapping_properties: { id: @pmp.id }
        ).readonly(false)
    end

    private

    def joined_appliance
      if prod_mode?
        Appliance.joins(appliance_type:
          { port_mapping_templates: :port_mapping_properties })
      else
        Appliance.joins(dev_mode_property_set:
          { port_mapping_templates: :port_mapping_properties })
      end
    end

    def prod_mode?
      @pmp.port_mapping_template.dev_mode_property_set.blank?
    end
  end
end
