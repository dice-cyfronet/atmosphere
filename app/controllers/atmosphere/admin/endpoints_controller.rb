class Admin::EndpointsController < Admin::ApplicationController

  # NOTE: all actions below do Ajax/JSON

  load_and_authorize_resource :appliance_type
  load_and_authorize_resource :port_mapping_template, through: :appliance_type
  load_and_authorize_resource :endpoint, through: :port_mapping_template
  layout false


  # GET /admin/appliance_types/1/port_mapping_templates/1/endpoints
  def index
    render partial: 'index'
  end

  # GET /admin/appliance_types/1/port_mapping_templates/1/endpoints/new
  def new
    render partial: 'edit'
  end

  # POST /admin/appliance_types/1/port_mapping_templates/1/endpoints
  def create
    @endpoint.save endpoint_params
    render_index
  end

  # GET /admin/appliance_types/1/port_mapping_templates/1/endpoints/1/edit
  def edit
    render partial: 'edit'
  end

  # PATCH/PUT /admin/appliance_types/1/port_mapping_templates/1/endpoints/1
  def update
    @endpoint.update endpoint_params
    render_index
  end

  # DELETE /admin/appliance_types/1/port_mapping_templates/1/endpoints/1
  def destroy
    @endpoint.destroy
    render_index
  end


  private

  # Only allow a trusted parameter "white list" through.
  def endpoint_params
    params.require(:endpoint).permit(:name, :endpoint_type, :description, :descriptor, :invocation_path, :port_mapping_template_id)
  end

  # Set a simple flash-like message for the user and show the PMTs index
  def render_index
    if @endpoint.errors.blank?
      @notice = "Endpoint was successfully #{request[:action]}ed.".gsub('ee','e') # ;)
    else
      @alert = @endpoint.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end

end
