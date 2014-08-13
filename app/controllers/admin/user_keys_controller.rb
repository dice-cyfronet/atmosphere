class Admin::UserKeysController < Admin::ApplicationController
  load_and_authorize_resource :user_key
  #before_filter :set_user_keys, only: :index

  def index
    # it really does the job :-)
    @user_keys = @user_keys.order(:name)
  end

  def show
    # it really does the job :-)
  end

  def new
    @users = User.all
  end

  def create
    if @user_key.save
      redirect_to action: :index, notice: 'User key created'
    else
      render action: 'new'
    end
  end

  def destroy
    @user_key.destroy
    redirect_to admin_user_keys_url, notice: 'User key destroyed'
  end

  private
  def user_key_params
    params.require(:user_key).permit([:public_key, :name, :user_id])
  end

end
