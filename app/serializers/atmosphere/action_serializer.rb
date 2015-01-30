#
# Action serializer.
#
module Atmosphere
  class ActionSerializer < ActiveModel::Serializer

    attributes :id, :action_type

    has_many :action_logs

  end
end
