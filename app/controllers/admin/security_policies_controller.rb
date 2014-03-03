class Admin::SecurityPoliciesController < Admin::ApplicationController
  load_and_authorize_resource :security_policy

  def index
    authenticate_user!
  end

  def new
  end

  def create
    if @security_policy.save
      flash[:notice] = I18n.t('security_policy.created')
      flash[:alert] = nil
      redirect_to admin_security_policies_path
    else
      flash[:error] = I18n.t('security_policy.create_error')
      render :new
    end
  end

  def edit
  end

  def update
    if @security_policy.update_attributes(security_policy_params)
      flash[:notice] = I18n.t('security_policy.updated')
      flash[:alert] = nil
      redirect_to admin_security_policies_path
    else
      flash[:error] = I18n.t('security_policy.update_error')
      render :edit
    end
  end

  def destroy
    @security_policy.destroy
    redirect_to admin_security_policies_path
  end

  def security_policy_params
    params.require(:security_policy).permit(:name, :payload, :user_ids)
  end
end
