class Atmosphere::Api::V1::VirtualMachineTemplatesController  < Atmosphere::Api::ApplicationController
  load_and_authorize_resource :virtual_machine_template,
    class: 'Atmosphere::VirtualMachineTemplate'

  respond_to :json

  def index
    respond_with @virtual_machine_templates.joins(:tenants).where(filter).
                     order(:id),
      each_serializer: Atmosphere::VirtualMachineTemplateSerializer,
      load_all?: load_all?
  end

  def model_class
    Atmosphere::VirtualMachineTemplate
  end

  private

  def filter
    filter = super
    filter[:atmosphere_tenants] = { id: current_user.tenants } unless load_all?
    filter
  end
end