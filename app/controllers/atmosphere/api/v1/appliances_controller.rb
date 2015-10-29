class Atmosphere::Api::V1::AppliancesController < Atmosphere::Api::ApplicationController
  before_filter :build_appliance, only: :create

  load_and_authorize_resource :appliance,
                              class: 'Atmosphere::Appliance'

  include Atmosphere::Api::Auditable

  before_filter :init_vm_search, only: :index

  respond_to :json

  def index
    respond_with @appliances.where(filter).order(:id)
  end

  def show
    respond_with @appliance
  end

  def create
    if Atmosphere::CreateApplianceService.new(@appliance).execute
      render json: @appliance, status: :created
    else
      render_error @appliance
    end
  end

  def update
    @appliance.update_attributes!(update_params)
    render json: @appliance
  end

  def destroy
    if Atmosphere::DestroyAppliance.new(@appliance).execute
      render json: {}
    else
      render_error @appliance
    end
  end

  def endpoints
    endpoints = Atmosphere::Endpoint.
                appl_endpoints(@appliance).order(:id).
                map { |endpoint| endpoint_hsh(endpoint) }

    render json: { endpoints: endpoints }
  end

  def action
    return reboot if reboot_action?
    return scale if scale_action?
    return pause if pause_action?
    return stop if stop_action?
    return suspend if suspend_action?
    return start if start_action?
    # place for other actions...

    render_json_error('Action not found', status: :bad_request)
  rescue Excon::Errors::Conflict => e
    begin
      body = JSON.parse(e.response.data[:body])
    rescue JSON::ParserError
      body = {}
    end

    conflicting = body.fetch('conflictingRequest',
                             'message' => 'Conflict', 'code' => 409)

    render_json_error(conflicting['message'],
                      status: conflicting['code'],
                      type: :conflict)
  end

  private

  def endpoint_hsh(endpoint)
    {
      id: endpoint.id,
      type: endpoint.endpoint_type,
      urls: endpoint_urls(endpoint)
    }
  end

  def endpoint_urls(endpoint)
    @appliance.http_mappings.
      where(port_mapping_template_id: endpoint.port_mapping_template_id).
      map { |mapping| "#{mapping.url}/#{endpoint.invocation_path}" }
  end

  def reboot
    authorize!(:reboot, @appliance)

    @appliance.virtual_machines.each(&:reboot)
    render json: {}, status: 200
  end

  def scale
    authorize!(:scale, @appliance)

    Atmosphere::Cloud::ScaleAppliance.
      new(@appliance, params[:scale].to_i).execute

    render json: {}, status: 200
  end

  def pause
    @appliance.virtual_machines.each(&:pause)
    render json: {}, status: 200
  end

  def stop
    @appliance.virtual_machines.each(&:stop)
    render json: {}, status: 200
  end

  def suspend
    @appliance.virtual_machines.each(&:suspend)
    render json: {}, status: 200
  end

  def start
    @appliance.virtual_machines.each(&:start)
    render json: {}, status: 200
  end

  def reboot_action?
    params.key? :reboot
  end

  def scale_action?
    params.key?(:scale)
  end

  def pause_action?
    params.key?(:pause)
  end

  def stop_action?
    params.key?(:stop)
  end

  def suspend_action?
    params.key?(:suspend)
  end

  def start_action?
    params.key?(:start)
  end

  def filter
    filter = super
    if vm_search?
      vm_ids = to_array(params[:virtual_machine_ids])
      filter[:atmosphere_deployments] = { virtual_machine_id: vm_ids }
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

  def build_appliance
    # The following rewrite is done to maintain compatibility with old clients
    if params[:appliance].key?('compute_site_ids')
      params[:appliance]['tenant_ids'] =
        params[:appliance].delete('compute_site_ids')
    end
    @appliance = Atmosphere::ApplianceCreator.
                 new(params.require(:appliance), delegate_auth).build
  end

  def load_admin_abilities?
    in_set_context? || super
  end

  def in_set_context?
    !params[:appliance_set_id].blank?
  end

  def model_class
    Atmosphere::Appliance
  end

  def optimizer
    Atmosphere::Optimizer.instance
  end
end
