class Atmosphere::Admin::ApplianceConfigurationTemplatesController < Atmosphere::Admin::ApplicationController

  # NOTE: all actions below do Ajax/JSON

  load_and_authorize_resource :appliance_type,
    class: 'Atmosphere::ApplianceType'

  load_and_authorize_resource :appliance_configuration_template,
    through: :appliance_type,
    class: 'Atmosphere::ApplianceConfigurationTemplate'

  layout false

  # GET /admin/appliance_types/1/appliance_configuration_templates
  def index
    render partial: 'index'
  end

  # GET /admin/appliance_types/1/appliance_configuration_templates/new
  def new
    render partial: 'edit'
  end

  # POST /admin/appliance_types/1/appliance_configuration_templates
  def create
    @appliance_configuration_template.save appliance_configuration_template_params
    render_index
  end

  # GET /admin/appliance_types/1/appliance_configuration_templates/1/edit
  def edit
    render partial: 'edit'
  end

  # PATCH/PUT /admin/appliance_types/1/appliance_configuration_templates/1
  def update
    @appliance_configuration_template.update appliance_configuration_template_params
    render_index
  end

  # DELETE /admin/appliance_types/1/appliance_configuration_templates/1
  def destroy
    @appliance_configuration_template.destroy
    render_index
  end


  private

  # Only allow a trusted parameter "white list" through.
  def appliance_configuration_template_params
    params.require(:appliance_configuration_template).permit(:name, :payload, :appliance_type_id)
  end

  # Set a simple flash-like message for the user and show the ACTs index
  def render_index
    if @appliance_configuration_template.errors.blank?
      @notice = "Appliance Configuration Template was successfully #{request[:action]}ed.".gsub('ee','e') # ;)
    else
      @alert = @appliance_configuration_template.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end

end
