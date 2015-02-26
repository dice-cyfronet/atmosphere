#
# User serializer. Normal user is able to see other users
# basic information. When user has admin role than (s)he
# is able to see other users email and roles.
#
module Atmosphere
  class UserSerializer < ActiveModel::Serializer
    include Atmosphere::UserSerializerExt
    attributes :id, :login, :full_name

    def attributes
      hash = super
      if show_details?
        hash['email'] = object.email
        hash['roles'] = object.roles.to_a
        additional_user_details(hash)
      end
      hash
    end

    private

    def show_details?
      scope.has_role?(:admin) || scope == object
    end
  end
end
