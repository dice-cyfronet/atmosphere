class Atmosphere::Admin::BillingLogsController < Atmosphere::Admin::ApplicationController
  authorize_resource :billing_log, class: 'Atmosphere::BillingLog'

  # GET /billing_logs
  # Pass user_id to get this user's fund consumption. No parameters
  # return all users fund consumption.
  def index
    billing_logs = Atmosphere::BillingLog.last_year

    @user = Atmosphere::User.find params[:user_id] if params[:user_id]
    billing_logs = billing_logs.where(user: @user) if @user

    billing_logs = billing_logs.sum_currency_by_month
    billing_logs = billing_logs.group_by{|x| x[0][0]}

    @data_series =
      if billing_logs.present?
        billing_logs.map do |bl_currency|
          {
            name: bl_currency.first,
            data: Atmosphere::BillingLog.month_data_series(bl_currency.second)
          }
        end
      else
        [{
          name: 'No consumption',
          data: [0]*12
        }]
      end.to_json

    render partial: 'atmosphere/admin/funds/billing', format: :html
  end

end
