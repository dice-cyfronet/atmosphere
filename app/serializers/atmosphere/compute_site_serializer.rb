#
# Compute site serializer. For normal user basic compute site data
# is returned. When current user has admin role than additionally
# compute site configuration is returned.
#
module Atmosphere
  class ComputeSiteSerializer < ActiveModel::Serializer
    embed :ids

    attributes :id, :site_id, :name, :location, :site_type, :technology

    def attributes
      hash = super
      hash['config'] = object.config if admin?
      hash
    end

    private

    def admin?
      scope.has_role? :admin
    end
  end
end
