#
# Tenant serializer. For normal user basic tenant data
# is returned. When current user has admin role than additionally
# tenant configuration is returned.
#
module Atmosphere
  class TenantSerializer < ActiveModel::Serializer
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

    def site_id
      object.tenant_id
    end

    def site_type
      object.tenant_type
    end
  end
end
