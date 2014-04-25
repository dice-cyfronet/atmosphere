#
# Security proxy serializer.
#
class SecurityProxySerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :payload
  has_many :users, key: :owners
end
