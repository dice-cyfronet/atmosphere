class Atmosphere::Admin::UserFundsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :user_fund,
                              class: 'Atmosphere::UserFund'

  # POST /user_funds
  def create
    if @user_fund.save
      redirect_to admin_funds_path,
                  notice: t('funds.add_user.success',
                            user: @user_fund.user.full_name,
                            fund: @user_fund.fund.name)
    else
      redirect_to admin_funds_path, alert: @user_fund.errors.full_messages
    end
  end

  # DELETE /user_funds/1
  def destroy
    @user_fund.destroy
    redirect_to admin_funds_url,
                notice: t('funds.remove_user.success',
                          user: @user_fund.user.full_name,
                          fund: @user_fund.fund.name)
  end


  private

  # Only allow a trusted parameter "white list" through.
  def user_fund_params
    params.require(:user_fund).permit(
      :fund_id, :user_id
    )
  end

end
