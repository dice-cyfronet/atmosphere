class Api::V1::ApplianceEndpointsController < Api::ApplicationController
  load_and_authorize_resource :appliance_type, parent: false

  def index
    render json: @appliance_types.where('id IN (SELECT appliance_type_id FROM port_mapping_templates where id IN (SELECT port_mapping_template_id from endpoints))').order(:id), each_serializer: ApplianceTypeEndpointsSerializer
  end
end
