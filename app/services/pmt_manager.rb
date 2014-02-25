class PmtManager

  def initialize(pmt, appl_updater_class=ApplianceProxyUpdater)
    @pmt = pmt
    @appl_updater_class = appl_updater_class
  end

  def save!
    pmt.save!
    update_affected_appliances
  end

  def destroy
    affected_appliances = Appliance.with_pmt(pmt).to_a
    pmt.destroy.tap do |destroyed|
      update_affected_appliances(affected_appliances) if destroyed
    end
  end

  def update!(update_params)
    pmt.update_attributes!(update_params)
    update_affected_appliances
  end

  private

  attr_reader :pmt, :appl_updater_class

  def update_affected_appliances(appl=Appliance.with_pmt(pmt))
    appl.each { |appl| appl_updater_class.new(appl).update }
  end
end