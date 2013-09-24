class Admin::ApplianceTypesController < ApplicationController
  load_and_authorize_resource :appliance_type

  # GET /admin/appliance_types
  def index
  end

  # GET /admin/appliance_types/1
  def show
    logger.debug @appliance_type.name
  end

  # GET /admin/appliance_types/1/edit
  def edit
  end

  # PATCH/PUT /admin/appliance_types/1
  def update
    if @appliance_type.update(appliance_type_params)
      redirect_to [:admin, @appliance_set], notice: 'ApplianceType was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /admin/appliance_types/1
  def destroy
    @appliance_type.destroy
    redirect_to admin_appliance_types_url, notice: 'ApplianceType was successfully destroyed.'
  end

  private

    # Only allow a trusted parameter "white list" through.
    def appliance_type_params
      params.require(:appliance_type).permit(
        :name, :description, :visibility, :shared, :scalable, :author,
        :preference_memory, :preference_disk,  :preference_cpu)
    end
end
