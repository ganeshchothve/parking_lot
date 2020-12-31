class Admin::UserRequestsController < AdminController
  include UserRequestsConcern
  before_action :set_lead
  before_action :set_user
  before_action :set_user_request, except: %i[index export new create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index export]
  after_action :authorize_after_action, only: %i[show new]

  layout :set_layout

  # permitted_user_request_attributes, set_user_request, apply_policy_scope, associated_class, authorize_resource and authorize_after_action from UserRequestsConcern

  # index defined in UserRequestsConcern
  # GET /admin/:request_type/users/:user_id/user_requests
  # GET /admin/:request_type/user_requests

  # new defined in UserRequestsConcern
  # GET /admin/:request_type/users/:user_id/user_requests/new
  # GET /admin/:request_type/user_requests/new

  # show defined in UserRequestsConcern
  # GET /admin/:request_type/users/:user_id/user_requests/:id
  # GET /admin/:request_type/user_requests/:id

  # edit defined in UserRequestsConcern
  # GET /admin/:request_type/users/:user_id/user_requests/:id/edit
  # GET /admin/:request_type/user_requests/:id/edit

  #
  # This is the create action for Admin, called after new to create a new user request.
  #
  # POST /admin/:request_type/users/:user_id/user_requests
  # POST /admin/:request_type/user_requests
  #
  def create
    @user_request = associated_class.new(user_id: @user.id, lead: @lead, created_by: current_user)
    @user_request.project = @lead.project if @lead.present?
    @user_request.assign_attributes(permitted_user_request_attributes)
    respond_to do |format|
      if @user_request.save
        format.html { redirect_to edit_admin_user_request_path(@user_request, request_type: @user_request.class.model_name.element), notice: 'Request registered successfully.' }
        format.json { render json: @user_request, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @user_request.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This export action for Admin users where Admin will get a report of all the user requests.
  #
  # GET /admin/:request_type/user_requests/export
  #
  def export
    if Rails.env.development?
      UserRequestExportWorker.new.perform(current_user.id.to_s, params[:fltrs].as_json)
    else
      UserRequestExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_user_requests_path(request_type: 'all', fltrs: params[:fltrs].as_json)
  end

  #
  # This is the update action for admin, users which is called after edit to resolve the request made by the user.
  #
  # PATCH /admin/:request_type/users/:user_id/user_requests/:id
  # PATCH /admin/:request_type/user_requests/:id
  #
  def update
    @user_request.assign_attributes(permitted_user_request_attributes)
    set_resolved_by
    respond_to do |format|
      if @user_request.save
        format.html { redirect_to admin_user_requests_path(request_type: 'all'), notice: 'User Request was successfully updated.' }
        format.json { render json: @user_request }
      else
        format.html { render :edit }
        format.json { render json: { errors: @user_request.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_lead
    @lead = (params[:lead_id].present? ? Lead.find(params[:lead_id]) : nil)
  end

  def set_user
    @user = @lead.present? ? @lead.user : current_user
  end

  def set_resolved_by
    if @user_request.status_changed?
      if @user_request._type == 'UserRequest::General' && @user_request.resolved?
        @user_request.resolved_by = current_user
      elsif @user_request.processing?
        @user_request.resolved_by = current_user
      end
    end
  end
end
