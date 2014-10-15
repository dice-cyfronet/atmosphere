class Atmosphere::Admin::ApplianceSetsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :appliance_set,
    class: 'Atmosphere::ApplianceSet'

  # GET /admin/appliance_sets
  def index
    @appliance_sets = @appliance_sets.joins(:user).order('atmosphere_users.login', priority: :desc).group_by(&:user)
  end

  # GET /admin/appliance_sets/1
  def show
  end

  # GET /admin/appliance_sets/1/edit
  def edit
  end

  # PATCH/PUT /admin/appliance_sets/1
  def update
    if @appliance_set.update(appliance_set_params)
      redirect_to [:admin, @appliance_set], notice: 'ApplianceSet was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /admin/appliance_sets/1
  def destroy
    @appliance_set.destroy
    redirect_to admin_appliance_sets_url, notice: 'ApplianceSet was successfully destroyed.'
  end

  private

    # Only allow a trusted parameter "white list" through.
    def appliance_set_params
      params[:appliance_set].permit(:appliance_set_type)
    end
end
