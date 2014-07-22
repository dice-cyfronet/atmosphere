

class ClewSerializer < ActiveModel::Serializer

  attribute :appliance

  def appliance
    object[:appliance]
  end

end