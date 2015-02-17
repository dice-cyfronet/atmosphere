#
# Action log serializer.
#
module Atmosphere
  class ActionLogSerializer < ActiveModel::Serializer
    attributes :id, :log_level, :message, :created_at
  end
end
