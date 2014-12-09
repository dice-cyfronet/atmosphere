class Atmosphere::Admin::ComputeSiteFundsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :compute_site_fund,
    class: 'Atmosphere::ComputeSiteFund'

  # POST /compute_site_funds
  def create
    if @compute_site_fund.save
      redirect_to admin_funds_path,
        notice:  t('funds.add_site.success',
                   cs: @compute_site_fund.compute_site.name,
                   fund: @compute_site_fund.fund.name)
    else
      redirect_to admin_funds_path, alert: @compute_site_fund.errors.full_messages
    end
  end

  # DELETE /compute_site_funds/1
  def destroy
    @compute_site_fund.destroy
    redirect_to admin_funds_url,
      notice:  t('funds.remove_site.success',
                 cs: @compute_site_fund.compute_site.name,
                 fund: @compute_site_fund.fund.name)
  end

  private
    # Only allow a trusted parameter "white list" through.
    def compute_site_fund_params
      params.require(:compute_site_fund).permit(
          :fund_id, :compute_site_id
      )
    end

end
