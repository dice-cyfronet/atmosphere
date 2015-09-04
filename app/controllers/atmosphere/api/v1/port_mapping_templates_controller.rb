class Atmosphere::Api::V1::PortMappingTemplatesController < Atmosphere::Api::ApplicationController
  before_filter :find_port_mapping_templates, only: :index

  load_and_authorize_resource :port_mapping_template,
    except: :index,
    class: 'Atmosphere::PortMappingTemplate'

  authorize_resource :port_mapping_template,
    only: :index,
    class: 'Atmosphere::PortMappingTemplate'

  include Atmosphere::Api::Auditable

  before_filter :initialize_manager, only: [:create, :update, :destroy]
  respond_to :json

  def index
    respond_with @port_mapping_templates.where(filter)
  end

  def show
    respond_with @port_mapping_template
  end

  def create
    @manager.save!
    render json: @manager.object, status: :created
  end

  def update
    @manager.update!(port_mapping_template_update_params)
    render json: @manager.object
  end

  def destroy
    if @manager.destroy
      render json: {}
    else
      render_error @manager.object
    end
  end

  private

  def find_port_mapping_templates
    if params[:appliance_type_id]
      @appliance_type = Atmosphere::ApplianceType.find(params[:appliance_type_id])
      @port_mapping_templates = Atmosphere::PortMappingTemplate.where(appliance_type: @appliance_type)
      authorize!(:index, @appliance_type)
    else
      @dev_mode_property_set = Atmosphere::DevModePropertySet.find(params[:dev_mode_property_set_id])
      @port_mapping_templates = Atmosphere::PortMappingTemplate.where(dev_mode_property_set: @dev_mode_property_set)
      authorize!(:index, @dev_mode_property_set.appliance.appliance_set)
    end
  end

  def port_mapping_template_params
    params.require(:port_mapping_template).permit(
        :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id, :dev_mode_property_set_id)
  end

  def port_mapping_template_update_params
    params.require(:port_mapping_template).
      permit(:service_name, :target_port,
             :transport_protocol, :application_protocol)
  end

  def initialize_manager
    @manager = Atmosphere::AffectedApplianceAwareManager
      .new(@port_mapping_template, Atmosphere::AppliancesAffectedByPmt)
  end

  def model_class
    Atmosphere::PortMappingTemplate
  end
end
