class Admin::EndpointsController < ApplicationController

  load_and_authorize_resource :appliance_type
  load_and_authorize_resource :port_mapping_template, through: :appliance_type
  #load_and_authorize_resource :endpoints, through: port_mapping_template
  layout false


  # GET /admin/endpoints
  def index
    render partial: 'index'
  end

  ## GET /admin/port_mapping_templates/1
  #def show
  #  render partial: 'show'
  #end
  #
  ## GET /admin/port_mapping_templates/new
  #def new
  #  render partial: 'edit'
  #end
  #
  ## POST /admin/port_mapping_templates
  #def create
  #  @port_mapping_template.save port_mapping_template_params
  #  render_index
  #end
  #
  ## GET /admin/port_mapping_templates/1/edit
  #def edit
  #  render partial: 'edit'
  #end
  #
  ## PATCH/PUT /admin/port_mapping_templates/1
  #def update
  #  @port_mapping_template.update port_mapping_template_params
  #  render_index
  #end
  #
  ## DELETE /admin/port_mapping_templates/1.json
  #def destroy
  #  @port_mapping_template.destroy
  #  render_index
  #end


  private

  ## Only allow a trusted parameter "white list" through.
  #def port_mapping_template_params
  #  params.require(:port_mapping_template).permit(
  #    :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id)
  #end
  #
  ## Set a simple flash-like message for the user and show the PMTs index
  #def render_index
  #  if @port_mapping_template.errors.blank?
  #    @notice = "Port Mapping was successfully #{request[:action]}ed.".gsub('ee','e') # ;)
  #  else
  #    @alert = @port_mapping_template.errors.full_messages.join('</br>')
  #  end
  #  render partial: 'index'
  #end

end
