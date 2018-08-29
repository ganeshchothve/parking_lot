class Admin::UserRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_user_request, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @user_requests = associated_class.build_criteria params
    @user_requests = @user_requests.paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    @user_request = associated_class.find(params[:id])
    authorize @user_request
  end

  def new
    @user_request = associated_class.new(user_id: @user.id)
    @user_request.project_unit_id = params[:project_unit_id] if params[:project_unit_id].present?
    authorize @user_request
    render layout: false
  end

  def create
    @user_request = associated_class.new(user_id: @user.id, created_by: current_user)
    @user_request.assign_attributes(permitted_attributes(@user_request))
    respond_to do |format|
      if @user_request.save
        format.html { redirect_to edit_user_user_request_path(@user_request), notice: 'Request registered successfully.' }
        format.json { render json: @user_request, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @user_request.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def export
    if Rails.env.development?
      UserRequestExportWorker.new.perform(current_user.id.to_s)
    else
      UserRequestExportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_user_requests_path
  end

  def edit
    render layout: false
  end

  def update
    @user_request.assign_attributes(permitted_attributes(@user_request))
    if @user_request.status == "resolved"
      @user_request.resolved_by = current_user
      @user_request.resolved_at = Time.now
    end

    respond_to do |format|
      if @user_request.save
        format.html { redirect_to (current_user.buyer? ? user_user_requests_path(@user) : admin_user_requests_path), notice: 'User Request was successfully updated.' }
        format.json { render json: @user_request }
      else
        format.html { render :edit }
        format.json { render json: @user_request.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_user_request
    @user_request = associated_class.find(params[:id])
  end

  def set_user
    if current_user.buyer?
      @user = current_user
    else
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize UserRequest
    elsif params[:action] == "new" || params[:action] == "create"
      authorize associated_class.new(user_id: @user.id)
    else
      authorize @user_request
    end
  end

  def associated_class
    if params[:request_type] == "swap"
        UserRequest::Swap
    elsif params[:request_type] == "cancellation"
      UserRequest::Cancellation
    else
      UserRequest
    end
  end

  def apply_policy_scope
    custom_scope = associated_class.where(associated_class.user_based_scope(current_user, params))
    if params[:request_type].present?
      type =
      custom_scope = custom_scope.where(_type: type)
    end
    associated_class.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
