class ComputeSitesController < ApplicationController
  before_action :set_compute_site, only: [:show, :edit, :update, :destroy]

  # GET /compute_sites
  def index
    @compute_sites = ComputeSite.all
  end

  # GET /compute_sites/1
  def show
  end

  # GET /compute_sites/new
  def new
    @compute_site = ComputeSite.new
  end

  # GET /compute_sites/1/edit
  def edit
  end

  # POST /compute_sites
  def create
    @compute_site = ComputeSite.new(compute_site_params)

    if @compute_site.save
      redirect_to @compute_site, notice: 'Compute site was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /compute_sites/1
  def update
    if @compute_site.update(compute_site_params)
      redirect_to @compute_site, notice: 'Compute site was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /compute_sites/1
  def destroy
    @compute_site.destroy
    redirect_to compute_sites_url, notice: 'Compute site was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_compute_site
      @compute_site = ComputeSite.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def compute_site_params
      params.require(:compute_site).permit(:site_id, :name, :location, :site_type)
    end
end
