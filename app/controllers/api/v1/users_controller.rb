class Api::V1::UsersController < ApisController
  before_action :authenticate_request
  before_action :set_user, except: :create
  before_action :erp_id_present?

  #
  # The create action always creates a new user from an external api request.
  #
  # POST  /api/v1/users
  #
  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  #
  # The update action will update the details of an existing user using the erp_id for identification.
  #
  # PATCH     /api/v1/users/:id
  #
  def update
    @user.assign_attributes(user_params)
    if @user.save
      render json: @user, status: :ok
    else
      render json: @user.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  private


  # Checks if the erp-id is present. Erp-id is the external api identification id.
  def erp_id_present?
    render json: { status: :bad_request, message: 'Erp-id is required.' } unless params[:user][:erp_id]
  end

  # Sets the user object
  def set_user
    @user = User.where(erp_id: params[:user][:erp_id]).first
    render json: { status: :not_found, message: 'User is not registered.' } if @user.blank?
  end

  # Allows only certain parameters to be saved and updated.
  def user_params
    params.fetch(:user, {}).permit(:erp_id, :lead_id, :first_name, :last_name, :email, :phone, :confirmed_at, :role, :booking_portal_client_id)
  end
end
