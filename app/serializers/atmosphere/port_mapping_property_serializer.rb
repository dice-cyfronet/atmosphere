#
# Port mapping property serializer.
#
class PortMappingPropertySerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :key, :value

  has_one :port_mapping_template
  has_one :compute_site
end
