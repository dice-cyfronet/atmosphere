class Atmosphere::Api::V1::VirtualMachineTemplatesController  < Atmosphere::Api::ApplicationController
  load_and_authorize_resource :virtual_machine_template
  respond_to :json

  def index
    respond_with @virtual_machine_templates.where(filter).order(:id)
  end
end