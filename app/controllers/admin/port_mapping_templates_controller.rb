class Admin::PortMappingTemplatesController < ApplicationController

  load_and_authorize_resource :appliance_type
  load_and_authorize_resource :port_mapping_template, through: :appliance_type#, shallow: true
  layout false

  # GET /admin/port_mapping_templates
  def index
    render partial: 'index'
  end

  # GET /admin/port_mapping_templates/1
  def show
    render partial: 'show'
  end

  # GET /admin/port_mapping_templates/new
  def new
    render partial: 'edit'
  end

  # POST /admin/port_mapping_templates
  def create
    if @port_mapping_template.save port_mapping_template_params
      @notice = 'Appliance Type was successfully added.'
    else
      @alert = @port_mapping_template.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end

  # GET /admin/port_mapping_templates/1/edit
  def edit
    render partial: 'edit'
  end

  # PATCH/PUT /admin/port_mapping_templates/1
  def update
    if @port_mapping_template.update port_mapping_template_params
      @notice = 'Appliance Type was successfully updated.'
    else
      @alert = @port_mapping_template.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end

  # DELETE /admin/port_mapping_templates/1.json
  def destroy
    if @port_mapping_template.destroy
      @notice = 'Port Mapping was successfully removed.'
    else
      @alert = @port_mapping_template.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end


  private

    # Only allow a trusted parameter "white list" through.
    def port_mapping_template_params
      params.require(:port_mapping_template).permit(
        :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id)
    end

end
