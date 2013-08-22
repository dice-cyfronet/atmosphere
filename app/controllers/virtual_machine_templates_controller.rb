class VirtualMachineTemplatesController < ApplicationController
  load_and_authorize_resource :virtual_machine_template

  # GET /virtual_machine_templates
  def index
  end

  # GET /virtual_machine_templates/1
  def show
  end

  # GET /virtual_machine_templates/new
  def new
  end

  # GET /virtual_machine_templates/1/edit
  def edit
  end

  # POST /virtual_machine_templates
  def create
    if @virtual_machine_template.save
      redirect_to @virtual_machine_template, notice: 'Virtual machine template was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /virtual_machine_templates/1
  def update
    if @virtual_machine_template.update(virtual_machine_template_params)
      redirect_to @virtual_machine_template, notice: 'Virtual machine template was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /virtual_machine_templates/1
  def destroy
    @virtual_machine_template.destroy
    redirect_to virtual_machine_templates_url, notice: 'Virtual machine template was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def virtual_machine_template_params
      params.require(:virtual_machine_template).permit(:id_at_site, :name, :state)
    end
end
