class Admin::PortMappingTemplatesController < ApplicationController

  load_and_authorize_resource :port_mapping_template
  #before_filter :set_appliance_types#, only: [:index, :show, :new, :create, :destroy]

  ## GET /admin/port_mapping_templates
  #def index
  #end

  # GET /admin/port_mapping_templates/1
  def show
    render partial: 'show', layout: false
  end

  ## GET /admin/port_mapping_templates/new
  #def new
  #end

  ## POST /admin/port_mapping_templates
  #def create
  #  if @appliance_type.save appliance_type_params
  #    redirect_to [:admin, @appliance_type], notice: 'Appliance Type was successfully created.'
  #  else
  #    render action: 'new'
  #  end
  #end

  # GET /admin/port_mapping_templates/1/edit
  def edit
    render partial: 'edit', layout: false
  end

  ## PATCH/PUT /admin/port_mapping_templates/1
  #def update
  #  if @appliance_type.update appliance_type_params
  #    redirect_to [:admin, @appliance_type], notice: 'Appliance Type was successfully updated.'
  #  else
  #    render action: 'edit'
  #  end
  #end

  # DELETE /admin/port_mapping_templates/1.json
  def destroy
    @appliance_type = @port_mapping_template.appliance_type
    if @port_mapping_template.destroy
      @notice = 'Port Mapping was successfully removed.'
    else
      @alert = @port_mapping_template.errors.full_messages.join('</br>')
    end
    render partial: 'index', layout: false
  end


  private

    #def set_appliance_types
    #  @appliance_types = (@appliance_types ? @appliance_types : ApplianceType.all).def_order
    #end
    #
    ## Only allow a trusted parameter "white list" through.
    #def appliance_type_params
    #  params.require(:appliance_type).permit(
    #    :name, :description, :visibility, :shared, :scalable, :user_id,
    #    :preference_memory, :preference_disk,  :preference_cpu)
    #end

end
