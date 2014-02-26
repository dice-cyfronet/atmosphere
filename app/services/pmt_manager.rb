class PmtManager

  attr_reader :port_mapping_template

  def initialize(port_mapping_template, appl_updater_class=ApplianceProxyUpdater)
    @port_mapping_template = port_mapping_template
    @appl_updater_class = appl_updater_class
  end

  def save!
    port_mapping_template.save!
    update_affected_appliances
  end

  def destroy
    affected_appliances = Appliance.with_pmt(port_mapping_template).to_a
    port_mapping_template.destroy.tap do |destroyed|
      update_affected_appliances(affected_appliances) if destroyed
    end
  end

  def update!(update_params)
    port_mapping_template.update_attributes!(update_params)
    update_affected_appliances
  end

  private

  attr_reader :appl_updater_class

  def update_affected_appliances(appl=Appliance.with_pmt(port_mapping_template))
    appl.each { |appl| appl_updater_class.new(appl).update }
  end
end