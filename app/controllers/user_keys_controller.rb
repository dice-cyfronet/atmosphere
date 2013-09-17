class UserKeysController < ApplicationController
  before_action :set_user_key, only: [:show, :edit, :update, :destroy]

  # GET /user_keys
  def index
    @user_keys = UserKey.all
  end

  # GET /user_keys/1
  def show
  end

  # GET /user_keys/new
  def new
    @user_key = UserKey.new
  end

  # GET /user_keys/1/edit
  def edit
  end

  # POST /user_keys
  def create
    @user_key = UserKey.new(user_key_params)

    if @user_key.save
      redirect_to @user_key, notice: 'User key was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /user_keys/1
  def update
    if @user_key.update(user_key_params)
      redirect_to @user_key, notice: 'User key was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /user_keys/1
  def destroy
    @user_key.destroy
    redirect_to user_keys_url, notice: 'User key was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_key
      @user_key = UserKey.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_key_params
      params.require(:user_key).permit(:name)
    end
end
