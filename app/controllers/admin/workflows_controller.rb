class Admin::WorkflowsController < ApplicationController
  authorize_resource
  before_action :set_workflow, only: [:show, :edit, :update, :destroy]

  # GET /admin/workflows
  def index
    @workflows = Workflow.all
  end

  # GET /admin/workflows/1
  def show
  end

  # GET /admin/workflows/1/edit
  def edit
  end

  # PATCH/PUT /admin/workflows/1
  def update
    if @workflow.update(workflow_params)
      redirect_to [:admin, @workflow], notice: 'Workflow was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /admin/workflows/1
  def destroy
    @workflow.destroy
    redirect_to admin_workflows_url, notice: 'Workflow was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workflow
      @workflow = Workflow.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workflow_params
      params[:workflow]
    end
end
