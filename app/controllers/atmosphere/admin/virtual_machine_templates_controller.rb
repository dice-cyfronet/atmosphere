class Atmosphere::Admin::VirtualMachineTemplatesController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :virtual_machine_template,
                              class: 'Atmosphere::VirtualMachineTemplate'

  before_filter :set_compute_sites, except: [:index, :show, :destroy]

  # GET /virtual_machine_templates
  def index
    @virtual_machine_templates = @virtual_machine_templates.
                                 joins(:compute_site).
                                 order('atmosphere_compute_sites.name').
                                 order('atmosphere_virtual_machine_templates.name').
                                 group_by(&:compute_site)
  end

  # GET /virtual_machine_templates/1
  def show
  end

  # GET /virtual_machine_templates/1/edit
  def edit
  end

  # GET /virtual_machine_templates/1/select_destination
  def select_destination
  end

  # POST /virtual_machine_templates/1/migrate
  def migrate
    cs_id = virtual_machine_template_params[:compute_site_id]
    @virtual_machine_template.export(cs_id)
    redirect_to admin_virtual_machine_templates_url,
                notice: 'Virtual machine template migration task was successfully enqueued.'
  end

  # PATCH/PUT /virtual_machine_templates/1
  def update
    if @virtual_machine_template.update(virtual_machine_template_params)
      if Atmosphere::Engine.routes.recognize_path(request.referrer)[:controller] == 'atmosphere/admin/appliance_types'
        redirect_to request.referer
      else
        redirect_to admin_virtual_machine_template_url(@virtual_machine_template),
                    notice: 'Virtual machine template was successfully updated.'
      end
    else
      render action: 'edit'
    end
  end

  # DELETE /virtual_machine_templates/1
  def destroy
    @virtual_machine_template.destroy
    redirect_to admin_virtual_machine_templates_url,
                notice: 'Virtual machine template was successfully destroyed.'
  end

  private

  # Only allow a trusted parameter "white list" through.
  def virtual_machine_template_params
    params.require(:virtual_machine_template).permit(:id_at_site, :name, :state,
                                                     :compute_site_id,
                                                     :virtual_machine_id,
                                                     :appliance_type_id)
  end
end
