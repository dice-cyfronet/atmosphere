class Atmosphere::Api::V1::EndpointsController < Atmosphere::Api::ApplicationController
  load_and_authorize_resource :endpoint,
    class: 'Atmosphere::Endpoint'

  include Atmosphere::Api::Auditable

  before_filter :find_endpoints, only: :index

  respond_to :json

  def index
    respond_with @endpoints.where(filter)
  end

  def show
    respond_with @endpoint
  end

  def create
    @endpoint.save!
    render json: @endpoint, status: :created
  end

  def update
    @endpoint.update_attributes!(endpoint_update_params)
    render json: @endpoint
  end

  def destroy
    if @endpoint.destroy
      render json: {}
    else
      render_error @endpoint
    end
  end

  def descriptor
    filter_params = {
      'descriptor_url' => descriptor_api_v1_endpoint_url(@endpoint)
    }

    render text: Atmosphere::ParamsRegexpable.filter(@endpoint.descriptor, filter_params)
  end

  private

  def find_endpoints
    authenticate_user!
    @endpoints = current_user && Atmosphere::Endpoint.visible_to(current_user)
  end

  def endpoint_params
    params.require(:endpoint).permit(:name, :endpoint_type, :description, :descriptor, :invocation_path, :port_mapping_template_id, :secured)
  end

  def endpoint_update_params
    params.require(:endpoint).
      permit(:name, :endpoint_type, :description, :descriptor,
             :invocation_path, :secured)
  end

  def model_class
    Atmosphere::Endpoint
  end
end
