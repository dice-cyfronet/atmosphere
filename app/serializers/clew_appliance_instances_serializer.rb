

class ClewApplianceInstancesSerializer < ActiveModel::Serializer

  attribute :appliance_set
  attribute :appliances

  def appliance_set
    { :id => object[:appliance_set].id }
  end

  def appliances
    object[:appliances].map do |appl|
      { :id => appl.id }
    end
  end

end