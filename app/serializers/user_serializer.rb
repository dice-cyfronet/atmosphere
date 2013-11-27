class UserSerializer < ActiveModel::Serializer
  attributes :id, :login, :full_name

  def attributes
    hash = super
    if scope.has_role? :admin
      hash["email"] = object.email
      hash["roles"] = object.roles.to_a
    end
    hash
  end
end
