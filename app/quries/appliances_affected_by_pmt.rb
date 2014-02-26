class AppliancesAffectedByPmt
  def initialize(pmt)
    @pmt = pmt
  end

  def find
    joined_appliance.where(port_mapping_templates: {id: @pmt.id})
  end

  private

  def joined_appliance
    @pmt.dev_mode_property_set.blank? ?
      Appliance.joins(appliance_type: :port_mapping_templates) :
      Appliance.joins(dev_mode_property_set: :port_mapping_templates)
  end
end