#
# Http mapping serializer with filtering capability.
#
class HttpMappingSerializer < ActiveModel::Serializer
  include RecordFilter
  embed :ids
  attributes :id, :application_protocol,
    :url, :monitoring_status, :custom_name, :custom_url
  has_one :appliance, :port_mapping_template

  can_filter_by :appliance_id
end
