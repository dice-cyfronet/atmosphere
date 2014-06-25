class Api::V1::AppliancesController < Api::ApplicationController
  before_filter :init_appliance, only: :create
  load_and_authorize_resource :appliance
  before_filter :init_vm_search, only: :index

  respond_to :json

  def index
    respond_with @appliances.where(filter).order(:id)
  end

  def show
    respond_with @appliance
  end

  def create
    log_user_action "create new appliance with following params #{params}"
    appliance = @creator.create!
    render json: appliance, status: :created
    log_user_action "appliance created: #{@appliance.to_json}"
  end

  def update
    log_user_action "update appliance #{@appliance.id} with following params #{params}"
    @appliance.update_attributes!(update_params)
    render json: @appliance
    log_user_action "appliance name updated: #{@appliance_type.to_json}"
  end

  def destroy
    log_user_action "destroy appliance #{@appliance.id}"
    if @appliance.destroy
      render json: {}
      log_user_action "appliance #{@appliance.id} destroyed"
    else
      render_error @appliance
    end
  end

  def endpoints
    endpoints = Endpoint.appl_endpoints(@appliance).order(:id).collect do |endpoint|
      {
        id: endpoint.id,
        type: endpoint.endpoint_type,
        urls: @appliance.http_mappings.where(port_mapping_template_id: endpoint.port_mapping_template_id).collect do |mapping|
          "#{mapping.url}/#{endpoint.invocation_path}"
        end
      }
    end

    render json: { endpoints: endpoints }
  end

  def action
    return reboot if reboot_action?
    # place for other actions...

    render_json_error('Action not found', status: :bad_request)
  end

  private

  def reboot
    authorize!(:reboot, @appliance)

    @appliance.virtual_machines.each { |vm| vm.reboot }
    render json: {}, status: 200
  end

  def reboot_action?
    params.has_key? :reboot
  end

  def filter
    filter = super
    if vm_search?
      vm_ids = to_array(params[:virtual_machine_ids])
      filter[:deployments] = { virtual_machine_id: vm_ids}
    end

    filter
  end

  def vm_search?
    params['virtual_machine_ids']
  end

  def init_vm_search
    @appliances = @appliances.joins(:deployments) if vm_search?
  end

  def update_params
    params.require(:appliance).permit(:name, :description)
  end

  def init_appliance
    @creator = ApplianceCreator.new(params.require(:appliance), mi_ticket)
    @appliance = @creator.appliance
  end

  def load_admin_abilities?
    in_set_context? || super
  end

  def in_set_context?
    !params[:appliance_set_id].blank?
  end

  def mi_ticket
    current_user ? current_user.mi_ticket : nil
  end
end
