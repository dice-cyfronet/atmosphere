class ComputeSiteSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :site_id, :name, :location, :site_type, :technology

  def attributes
    hash = super
    if scope.has_role? :admin
      hash["config"] = object.config
    end
    hash
  end
end