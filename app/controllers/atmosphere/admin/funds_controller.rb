class Atmosphere::Admin::FundsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :fund, class: 'Atmosphere::Fund'

  # GET /funds
  def index
    @funds = @funds.order :name
  end

  # GET /funds/new
  def new
  end

  # GET /funds/1/edit
  def edit
  end

  # POST /funds
  def create
    if @fund.save
      redirect_to admin_funds_path, notice: t('funds.new.success')
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /funds/1
  def update
    if @fund.update(update_params)
      redirect_to admin_funds_path, notice: t('funds.update.success')
    else
      render action: 'edit'
    end
  end

  # DELETE /funds/1
  def destroy
    @fund.destroy
    redirect_to admin_funds_url, notice: t('funds.destroy.success')
  end


  private

  def update_params
    params.require(:fund).
      permit(:balance, :overdraft_limit,
             :currency_label, :termination_policy)
  end

  def fund_params
    params.require(:fund).permit(
        :name,
        :balance, :overdraft_limit, :currency_label,
        :termination_policy
    )
  end

end
