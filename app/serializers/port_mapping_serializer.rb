#
# Port mapping serializer.
#
class PortMappingSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :public_ip, :source_port
  has_one :port_mapping_template, :virtual_machine
end
