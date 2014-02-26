class AffectedApplianceAwareManager
  attr_reader :object

  def initialize(object, affected_appliances_query_class, appl_updater_class=ApplianceProxyUpdater)
    @object = object
    @appl_updater_class = appl_updater_class
    @affected_appliances_query_class = affected_appliances_query_class
  end

  def save!
    object.save!
    update_affected_appliances
  end

  def destroy
    affected_appliances_array = affected_appliances.to_a
    object.destroy.tap do |destroyed|
      update_affected_appliances(affected_appliances) if destroyed
    end
  end

  def update!(update_params)
    object.update_attributes!(update_params)
    update_affected_appliances
  end

  private

  attr_reader :appl_updater_class, :affected_appliances_query_class

  def update_affected_appliances(appl=affected_appliances)
    appl.each { |appl| appl_updater_class.new(appl).update }
  end

  def affected_appliances
    affected_appliances_query_class.new(object).find
  end
end