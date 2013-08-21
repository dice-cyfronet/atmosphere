class VirtualMachinesController < ApplicationController
  before_action :set_virtual_machine, only: [:show, :edit, :update, :destroy]

  # GET /virtual_machines
  def index
    @virtual_machines = VirtualMachine.all
  end

  # GET /virtual_machines/1
  def show
  end

  # GET /virtual_machines/new
  def new
    @virtual_machine = VirtualMachine.new
  end

  # GET /virtual_machines/1/edit
  def edit
  end

  # POST /virtual_machines
  def create
    @virtual_machine = VirtualMachine.new(virtual_machine_params)

    if @virtual_machine.save
      redirect_to @virtual_machine, notice: 'Virtual machine was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /virtual_machines/1
  def update
    if @virtual_machine.update(virtual_machine_params)
      redirect_to @virtual_machine, notice: 'Virtual machine was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /virtual_machines/1
  def destroy
    @virtual_machine.destroy
    redirect_to virtual_machines_url, notice: 'Virtual machine was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_virtual_machine
      @virtual_machine = VirtualMachine.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def virtual_machine_params
      params.require(:virtual_machine).permit(:id_at_site, :name, :state, :ip)
    end
end
