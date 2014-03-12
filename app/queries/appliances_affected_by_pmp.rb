class AppliancesAffectedByPmp
  def initialize(pmp)
    @pmp = pmp
  end

  def find
    joined_appliance.where(
        port_mapping_properties: {id: @pmp.id}
      ).readonly(false)
  end

  private

  def joined_appliance
    @pmp.port_mapping_template.dev_mode_property_set.blank? ?
      Appliance.joins(appliance_type: {port_mapping_templates: :port_mapping_properties}) :
      Appliance.joins(dev_mode_property_set:  {port_mapping_templates: :port_mapping_properties})
  end
end