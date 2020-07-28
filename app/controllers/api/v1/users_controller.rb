class Api::V1::UsersController < ApisController
  before_action :set_user, except: :create
  before_action :reference_id_present?, only: :create

  #
  # The create action always creates a new user from an external api request.
  #
  # POST  /api/v1/users
  #
  def create
    @user = User.new(user_create_params)
    if @user.save
      @user.update_external_ids(third_party_reference_params, @crm.id) if third_party_reference_params
      render json: {id: @user.id, message: 'User successfully created.'}, status: :created
    else
      render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
    end
   rescue StandardError => e
    create_error_log e
  end

  #
  # The update action will update the details of an existing user using the erp_id for identification.
  #
  # PATCH     /api/v1/users/:id
  #
  def update
    @user.assign_attributes(user_update_params)
    if @user.save
      @user.update_external_ids(third_party_reference_params, @crm.id) if third_party_reference_params
      render json: {id: @user.id, message: 'User successfully updated.'}, status: :ok
    else
      render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
    end
    rescue StandardError => e
      create_error_log e
  end

  private

  def third_party_reference_params
    params.dig(:user, :ids).try(:permit, User::THIRD_PARTY_REFERENCE_IDS)
  end

  # Checks if the erp-id is present. Erp-id is the external api identification id.
  def reference_id_present?
    render json: { errors: ['Reference id is required to create User'] }, status: :bad_request unless params.dig(:user, :ids, :reference_id)
  end

  # Sets the user object
  def set_user
    @user = User.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:id)).first
    render json: { errors: ['User is not registered.'] }, status: :not_found if @user.blank?
  end

  # Allows only certain parameters to be saved and updated.
  def user_create_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end

  def user_update_params
    params.require(:user).permit(:first_name, :last_name)
  end
end
