class Admin::VirtualMachinesController < ApplicationController
  load_and_authorize_resource :virtual_machine#, :except => :create
  #authorize_resource only: :create
  before_filter :set_virtual_machine_templates, :only => [:new, :create]

  # GET /virtual_machines
  def index
  end

  # GET /virtual_machines/1
  def show
  end

  # GET /virtual_machines/new
  def new
  end

  # GET /virtual_machines/1/edit
  #def edit  
  #end

  # POST /virtual_machines
  def create
    if @virtual_machine.save
      redirect_to admin_virtual_machine_url(@virtual_machine), notice: 'Virtual machine was successfully created.'
    else
      logger.info "Errors #{@virtual_machine.errors.messages}"
      render action: 'new'
    end
  end

  # PATCH/PUT /virtual_machines/1
  #def update
  #   if @virtual_machine.update(virtual_machine_params)
  #     redirect_to admin_virtual_machine_url(@virtual_machine), notice: 'Virtual machine was successfully updated.'
  #   else
  #     render action: 'edit'
  #   end
  # end

  # DELETE /virtual_machines/1
  def destroy
    @virtual_machine.destroy
    redirect_to admin_virtual_machines_url, notice: 'Virtual machine was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def virtual_machine_params
      params.require(:virtual_machine).permit(:virtual_machine_template_id, :name)
    end

    def set_virtual_machine_templates
      @virtual_machine_templates = VirtualMachineTemplate.all 
    end

end
