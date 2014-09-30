#
# User key serializer.
#
module Atmosphere
  class UserKeySerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :name, :fingerprint, :public_key
    has_one :user
  end
end