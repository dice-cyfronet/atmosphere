class Admin::VirtualMachinesController < Admin::ApplicationController
  load_and_authorize_resource :virtual_machine

  def index
  end

  def show
  end

  def save_as_template
    if VirtualMachineTemplate.create_from_vm(@virtual_machine)
      redirect_to admin_virtual_machine_templates_url, notice: 'Template is being saved'
    else
      redirect_to admin_virtual_machines_url, notice: 'Error while saving template'
    end
  end

  def reboot
    @virtual_machine.reboot
    redirect_to admin_virtual_machines_url
  end

  def destroy
    @virtual_machine.destroy
    redirect_to admin_virtual_machines_url, notice: 'Virtual machine was successfully destroyed.'
  end

  private
    def virtual_machine_params
      params.require(:virtual_machine).permit(:virtual_machine_template_id, :name, {:appliance_ids => []})
    end
end
