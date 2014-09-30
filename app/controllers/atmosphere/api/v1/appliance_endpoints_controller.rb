class Atmosphere::Api::V1::ApplianceEndpointsController < Atmosphere::Api::ApplicationController
  load_and_authorize_resource :appliance_type, parent: false
  before_filter :set_filter
  before_filter :limit_appliance_types

  def index
    endpoint_types = params[:endpoint_type].to_s.split(',')

    render json: @appliance_types.order(:id), each_serializer: ApplianceTypeEndpointsSerializer, endpoint_types: @endpoint_types
  end

  private

  def set_filter
    @endpoint_types = params[:endpoint_type].to_s.split(',') if params[:endpoint_type]
    @endpoint_ids = params[:endpoint_id].to_s.split(',') if params[:endpoint_id]
  end

  def limit_appliance_types
    @appliance_types = if @endpoint_ids
        @appliance_types.where("id IN (SELECT appliance_type_id FROM port_mapping_templates where id IN (SELECT port_mapping_template_id from endpoints WHERE id IN (?)))", @endpoint_ids)
      elsif @endpoint_types
        @appliance_types.where("id IN (SELECT appliance_type_id FROM port_mapping_templates where id IN (SELECT port_mapping_template_id from endpoints WHERE endpoint_type IN (?)))", @endpoint_types)
      else
        @appliance_types.where('id IN (SELECT appliance_type_id FROM port_mapping_templates where id IN (SELECT port_mapping_template_id from endpoints))')
      end
  end


end
