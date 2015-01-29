#
# Action serializer.
#
module Atmosphere
  class ActionSerializer < ActiveModel::Serializer

    attributes :id

    has_many :action_logs

  end
end
