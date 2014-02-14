class Admin::SecurityProxiesController < ApplicationController
  load_and_authorize_resource :security_proxy

  def index
    authenticate_user!
  end

  def new
  end

  def create
    if @security_proxy.save
      flash[:notice] = I18n.t('security_proxy.created')
      flash[:alert] = nil
      redirect_to admin_security_proxies_path
    else
      flash[:error] = I18n.t('security_proxy.create_error')
      render :new
    end
  end

  def update
    if @security_proxy.update_attributes(security_proxy_params)
      flash[:notice] = I18n.t('security_proxy.updated')
      flash[:alert] = nil
      redirect_to admin_security_proxies_path
    else
      flash[:error] = I18n.t('security_proxy.update_error')
      render :edit
    end
  end

  def destroy
    @security_proxy.destroy
    redirect_to admin_security_proxies_path
  end

  def security_proxy_params
    params.require(:security_proxy).permit(:name, :payload, :user_ids)
  end
end
