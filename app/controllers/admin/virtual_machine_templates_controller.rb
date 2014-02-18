class Admin::VirtualMachineTemplatesController < ApplicationController
  load_and_authorize_resource :virtual_machine_template
  before_filter :set_compute_sites, :except => [:index, :show, :destroy]

  # GET /virtual_machine_templates
  def index
  end

  # GET /virtual_machine_templates/1
  def show
  end

  # GET /virtual_machine_templates/1/edit
  def edit
  end

  # PATCH/PUT /virtual_machine_templates/1
  def update
    if @virtual_machine_template.update(virtual_machine_template_params)
      if Rails.application.routes.recognize_path(request.referrer)[:controller] == 'admin/appliance_types'
        redirect_to request.referer
      else
        redirect_to admin_virtual_machine_template_url(@virtual_machine_template), notice: 'Virtual machine template was successfully updated.'
      end
    else
      render action: 'edit'
    end
  end

  # DELETE /virtual_machine_templates/1
  def destroy
    @virtual_machine_template.destroy
    redirect_to admin_virtual_machine_templates_url, notice: 'Virtual machine template was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def virtual_machine_template_params
      params.require(:virtual_machine_template).permit(:id_at_site, :name, :state, :compute_site_id, :virtual_machine_id, :appliance_type_id)
    end
end
