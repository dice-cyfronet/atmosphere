class Atmosphere::Admin::TenantFundsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :tenant_fund,
                              class: 'Atmosphere::TenantFund'

  # POST /tenant_funds
  def create
    if @tenant_fund.save
      redirect_to admin_funds_path,
                  notice: t('funds.add_site.success',
                            cs: @tenant_fund.tenant.name,
                            fund: @tenant_fund.fund.name)
    else
      redirect_to admin_funds_path,
                  alert: @tenant_fund.errors.full_messages
    end
  end

  # DELETE /tenant_funds/1
  def destroy
    @tenant_fund.destroy
    redirect_to admin_funds_url,
                notice: t('funds.remove_site.success',
                          cs: @tenant_fund.tenant.name,
                          fund: @tenant_fund.fund.name)
  end


  private

  # Only allow a trusted parameter "white list" through.
  def tenant_fund_params
    params.require(:tenant_fund).permit(
      :fund_id, :tenant_id
    )
  end

end
