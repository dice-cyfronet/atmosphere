class AffectedApplianceAwareManager
  attr_reader :object

  def initialize(object, affected_appliances_query_class, appl_updater_class=Proxy::ApplianceProxyUpdater)
    @object = object
    @appl_updater_class = appl_updater_class
    @affected_appliances_query_class = affected_appliances_query_class
  end

  def save!
    object.save!
    update_affected_appliances(saved: object)
  end

  def destroy
    affected_appliances_array = affected_appliances.to_a
    object.destroy.tap do |destroyed|
      update_affected_appliances(
        affected_appliances_array,
        destroyed: object
      ) if destroyed
    end
  end

  def update!(update_params)
    old_object = frozen_copy
    object.update_attributes!(update_params)
    update_affected_appliances(updated: object, old: old_object)
  end

  private

  attr_reader :appl_updater_class, :affected_appliances_query_class

  def update_affected_appliances(appls=affected_appliances, options)
    appls.each { |appl| appl_updater_class.new(appl).update(options) }
  end

  def affected_appliances
    affected_appliances_query_class.new(object).find
  end

  def frozen_copy
    old_object = object.dup
    old_object.id = object.id
    old_object.freeze
  end
end