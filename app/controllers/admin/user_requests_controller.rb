class Admin::UserRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_user_request, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @user_requests = UserRequest.build_criteria params
    @user_requests = @user_requests.paginate(page: params[:page] || 1, per_page: 15)
  end

  def show
    @user_request = UserRequest.find(params[:id])
    authorize @user_request
  end

  def new
    @user_request = @user.user_requests.new
    @user_request.project_unit_id = params[:project_unit_id] if params[:project_unit_id].present?
    authorize @user_request
  end

  def create
    @user_request = @user.user_requests.new
    @user_request.assign_attributes(permitted_attributes(@user_request))

    respond_to do |format|
      if @user_request.save
        format.html { redirect_to edit_user_user_request_path(@user_request), notice: 'Request registered successfully.' }
      else
        format.html { render :new }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @user_request.update(permitted_attributes(@user_request))
        format.html { redirect_to (current_user.role?('user') ? user_user_requests_path(@user) : admin_user_requests_path), notice: 'User Request was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @user_request.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_user_request
    @user_request = UserRequest.find(params[:id])
  end

  def set_user
    if current_user.role?("user")
      @user = current_user
    else
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize UserRequest
    elsif params[:action] == "new" || params[:action] == "create"
      authorize UserRequest.new(user_id: @user.id)
    else
      authorize @user_request
    end
  end

  def apply_policy_scope
    custom_scope = UserRequest.all.criteria
    if current_user.role?('admin') || current_user.role?('crm')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      end
    else
      custom_scope = custom_scope.where(user_id: current_user.id)
    end
    UserRequest.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
