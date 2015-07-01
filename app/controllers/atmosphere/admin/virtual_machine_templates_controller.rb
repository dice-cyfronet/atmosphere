class Atmosphere::Admin::VirtualMachineTemplatesController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :virtual_machine_template,
                              class: 'Atmosphere::VirtualMachineTemplate'

  before_filter :set_tenants, except: [:index, :show, :destroy]

  # GET /virtual_machine_templates
  def index
    @virtual_machine_templates = @virtual_machine_templates.
                                 joins(:tenant).
                                 order('atmosphere_tenants.name').
                                 order('atmosphere_virtual_machine_templates.name').
                                 group_by(&:tenant)
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
    t_id = virtual_machine_template_params[:tenant_id]
    @virtual_machine_template.export(t_id)
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

  def set_tenants
    @tenants = Atmosphere::Tenant.all
  end

  # Only allow a trusted parameter "white list" through.
  def virtual_machine_template_params
    params.require(:virtual_machine_template).permit(:id_at_site, :name, :state,
                                                     :tenant_id,
                                                     :virtual_machine_id,
                                                     :appliance_type_id)
  end
end
