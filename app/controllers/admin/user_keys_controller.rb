class Admin::UserKeysController < ApplicationController
  load_and_authorize_resource :user_key

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    if @user_key.save
      redirect_to action: :index, notice: 'User key created'
    else
      render action: 'new'
    end
  end

  private
    def user_key_params
        params.require(:user_key).permit([:public_key, :name])
    end
end