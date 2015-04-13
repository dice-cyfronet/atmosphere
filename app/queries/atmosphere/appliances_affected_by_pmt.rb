#
# Find all appliances affected by given port mapping template.
#
module Atmosphere
  class AppliancesAffectedByPmt
    def initialize(pmt)
      @pmt = pmt
    end

    def find
      joined_appliance.
        where(atmosphere_port_mapping_templates: { id: @pmt.id }).
        readonly(false)
    end

    private

    def joined_appliance
      if prod_mode?
        Appliance.
          joins(appliance_type: :port_mapping_templates).
          where(only_prod_appliances)
      else
        Appliance.joins(dev_mode_property_set: :port_mapping_templates)
      end
    end

    def only_prod_appliances
      <<-SQL
        atmosphere_appliances.id NOT IN (
          SELECT DISTINCT(appliance_id)
            FROM atmosphere_dev_mode_property_sets)
      SQL
    end

    def prod_mode?
      @pmt.dev_mode_property_set.blank?
    end
  end
end