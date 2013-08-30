class UserSerializer < ActiveModel::Serializer
  attributes :id, :login, :email, :full_name
end
