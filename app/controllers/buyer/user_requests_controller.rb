class Buyer::UserRequestsController < BuyerController
  include UserRequestsConcern
  before_action :set_user
  before_action :set_user_request, except: %i[index export new create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index export]
  after_action :authorize_after_action, only: %i[show new]

  layout :set_layout

  # permitted_user_request_attributes, set_user_request, apply_policy_scope, associated_class, authorize_resource and authorize_after_action from UserRequestsConcern

  # index defined in UserRequestsConcern
  # GET /buyer/:request_type/user_requests

  # new defined in UserRequestsConcern
  # GET /buyer/:request_type/user_requests/new

  # show defined in UserRequestsConcern
  # GET /buyer/:request_type/user_requests/:id

  # edit defined in UserRequestsConcern
  # GET /buyer/:request_type/user_requests/:id/edit

  #
  # This is the create action for users, called after new to create a new user request.
  #
  # POST /buyer/:request_type/user_requests
  #
  def create
    @user_request = associated_class.new(user_id: @user.id, created_by: current_user)
    @user_request.assign_attributes(permitted_user_request_attributes)
    respond_to do |format|
      if @user_request.save
        format.html { redirect_to edit_buyer_user_request_path(@user_request, request_type: @user_request.class.model_name.element), notice: I18n.t("controller.notice.registered", name: "Request") }
        format.json { render json: @user_request, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @user_request.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This is the update action for users which is called after edit the request made by the user.
  #
  # PATCH /buyer/:request_type/user_requests/:id
  #
  def update
    @user_request.assign_attributes(permitted_user_request_attributes)
    respond_to do |format|
      if @user_request.save
        format.html { redirect_to user_buyer_requests_path(@user, request_type: 'all'), notice: I18n.t("controller.notice.updated", name: "User Request") }
        format.json { render json: @user_request }
      else
        format.html { render :edit }
        format.json { render json: { errors: @user_request.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = current_user
  end
end
