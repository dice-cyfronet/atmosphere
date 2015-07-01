class Atmosphere::Admin::TenantsController < Atmosphere::Admin::ApplicationController
  load_and_authorize_resource :tenant,
    class: 'Atmosphere::Tenant'

  # GET /tenants
  def index
    @tenants = @tenants.order(:name)
  end

  # GET /tenants/1
  def show
  end

  # GET /tenants/new
  def new
  end

  # GET /tenants/1/edit
  def edit
  end

  # POST /tenants
  def create
    if @tenant.save
      redirect_to admin_compute_sites_url(@tenant), notice: 'Tenant was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /tenants/1
  def update
    if @tenant.update(tenant_params)
      ::Proxy::TenantUrlUpdater.new(@tenant).update if @tenant.proxy_urls_changed?
      ::Proxy::TenantAppliancesUpdater.new(@tenant).update if @tenant.tenant_id_previously_changed?

      redirect_to admin_compute_sites_url(@tenant), notice: 'Tenant was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /tenants/1
  def destroy
    @tenant.destroy
    redirect_to admin_compute_sites_url, notice: 'Tenant was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def tenant_params
      params.require(:tenant).permit(
        :tenant_id, :name, :active, :location, :tenant_type,
        :technology, :config, :template_filters,
        :http_proxy_url, :https_proxy_url, :wrangler_url,
        :wrangler_username, :wrangler_password)
    end
end
