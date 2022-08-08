class Admin::WorkflowsController < AdminController

  before_action :fetch_pipeline_details, only: %i[index new edit]
  before_action :set_workflow, only: %i[edit update]

  def index
    @workflows = Workflow.build_criteria params
    @workflows = @workflows.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html {}
      format.json {}
    end
  end

  def new
    @workflow = Workflow.new
  end

  def create
    @workflow = Workflow.new(booking_portal_client_id: current_user.booking_portal_client_id)
    @workflow.assign_attributes(permitted_attributes([:admin, @workflow]))
    respond_to do |format|
      if @workflow.save
        format.html { redirect_to admin_workflows_path, notice: 'Workflow created successfully.' }
        format.json { render json: @workflow, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @workflow.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @workflow.update(permitted_attributes([:admin, @workflow]))
        format.html { redirect_to admin_workflows_path, notice: 'Workflow was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @workflow.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def pipeline_stages
    @pipelines_stages = Kylas::FetchPipelineStageDetails.new(current_user, params[:pipeline_id]).call
    if params[:workflow_id].present?
      @wf = Workflow.where(id: params[:workflow_id]).first
      if @wf.present?
        wf_pipeline = @wf.pipelines.where(pipeline_id: params[:pipeline_id]).first
        @selected_stage = wf_pipeline&.pipeline_stage_id
        @reason = wf_pipeline&.lead_closed_reason
      end
    end

    if @pipelines_stages[:success]
      render json: { 
                  pipeline_stages: @pipelines_stages[:data][:stages_details], 
                  selected_stage: @selected_stage,
                  reason: @reason
                  }
    else
      render json: { error: @pipelines_stages[:error] }, status: :unprocessable_entity
    end
  end

  private

  def fetch_pipeline_details
    @pipelines = Kylas::FetchPipelineDetails.new(current_user).call
  end

  def set_workflow
    @workflow = Workflow.where(id: params[:id]).first
    redirect_to admin_workflows_path, alert: 'Workflow not found' unless @workflow
  end
end