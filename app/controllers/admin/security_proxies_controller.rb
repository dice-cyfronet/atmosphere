class Admin::SecurityProxiesController < ApplicationController
  load_and_authorize_resource :security_proxy

  def index

  end

  def new

  end

  def security_proxy_params
    params.require(:security_proxy).permit(:name, :payload, :user_ids)
  end
end
