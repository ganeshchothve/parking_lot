class Admin::WorkflowsController < AdminController
  before_action :fetch_pipeline_details, only: %i[index new edit]
  before_action :set_workflow, only: %i[edit update enable_disable_workflow destroy]
  around_action :apply_policy_scope, only: :index
  before_action :authorize_resource

  def index
    @workflows = Workflow.build_criteria params
    @workflows = @workflows.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html {}
      format.json {}
    end
  end

  def new
    @workflow = Workflow.new(booking_portal_client_id: current_user.booking_portal_client.id)
  end

  def create
    @workflow = Workflow.new(booking_portal_client_id: current_user.booking_portal_client_id)
    @workflow.assign_attributes(permitted_attributes([:admin, @workflow]))
    respond_to do |format|
      if @workflow.save
        format.html { redirect_to admin_workflows_path, notice: I18n.t("controller.workflows.notice.created") }
        format.json { render json: @workflow, status: :created }
      else
        errors = []
        if @workflow.errors.messages.has_key?(:pipelines)
          errors << @workflow.pipelines.map{ |pipeline| pipeline.errors.full_messages  }.flatten rescue []
        else
          errors << @workflow.errors.full_messages.uniq
        end
        flash.now[:alert] = errors.flatten.uniq
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
        fetch_pipeline_details
        errors = []
        if @workflow.errors.messages.has_key?(:pipelines)
          errors << @workflow.pipelines.map{ |pipeline| pipeline.errors.full_messages }.flatten rescue []
        else
          errors << @workflow.errors.full_messages.uniq
        end
        flash.now[:alert] = errors.flatten.uniq
        format.html { render :edit }
        format.json { render json: { errors: @workflow.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def pipeline_stages
    @pipelines_stages = Kylas::FetchPipelineStageDetails.new(current_user, params[:pipeline_id]).call
    if params[:workflow_id].present?
      @wf = Workflow.where(booking_portal_client_id: current_client.try(:id), id: params[:workflow_id]).first
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

  def enable_disable_workflow
    respond_to do |format|
      if @workflow.update(is_active: (params[:is_active] == "true" ? true : false))
        format.html { redirect_to admin_workflows_path, notice: I18n.t("controller.workflows.notice.updated") }
      else
        format.html { redirect_to admin_workflows_path, alert: @workflow.errors.full_messages.uniq }
        format.json { render json: { errors: @workflow.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @workflow.destroy
        format.html { redirect_to admin_workflows_path, notice: I18n.t("controller.workflows.notice.deleted") }
      else
        format.html { redirect_to admin_workflows_path, notice: I18n.t("controller.workflows.notice.cannot_be_deleted") }
      end
    end
  end

  private

  def authorize_resource
    if %(index export pipeline_stages).include?params[:action]
      authorize [:admin, Workflow]
    elsif params[:action] == 'new'
      authorize [:admin, Workflow.new]
    elsif params[:action] == 'create'
      authorize [:admin, Workflow.new(permitted_attributes([:admin, Workflow.new]))]
    else
      authorize [:admin, @workflow]
    end
  end

  def fetch_pipeline_details
    @pipelines = Kylas::FetchPipelineDetails.new(current_user).call
  end

  def set_workflow
    @workflow = Workflow.where(booking_portal_client_id: current_client.try(:id), id: params[:id]).first
    redirect_to admin_workflows_path, alert: 'Workflow not found' unless @workflow
  end

  def apply_policy_scope
    custom_scope = Workflow.where(Workflow.user_based_scope(current_user, params))
    Workflow.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
