class Api::V1::UsersController < ApisController
  include Api::KylasUsersConcern

  before_action :set_user, except: %w[create create_or_update_user]
  before_action :set_client, only: %w[create_or_update_user]
  before_action :reference_id_present?, only: :create

  #
  # The create action always creates a new user from an external api request.
  #
  # POST  /api/v1/users
  #
  def create
    @user = User.new(user_create_params)
    @user.booking_portal_client_id = @current_client.try(:id)
    if @user.save
      @user.update_external_ids(third_party_reference_params, @crm.id) if third_party_reference_params
      render json: {id: @user.id, message: I18n.t("controller.users.notice.created")}, status: :created
    else
      render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
    end
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
      render json: {id: @user.id, message: I18n.t("controller.users.notice.updated")}, status: :ok
    else
      render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
    end
  end

  def create_or_update_user
    register_or_update_sales_user
    if @user.save
      @user.confirm if @user.unconfirmed_email.present?
      render json: {id: @user.id, message: I18n.t("controller.users.notice.created")}, status: :created
    else
      render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity
    end
  end

  private

  def third_party_reference_params
    params.dig(:user, :ids).try(:permit, User::THIRD_PARTY_REFERENCE_IDS)
  end

  # Checks if the erp-id is present. Erp-id is the external api identification id.
  def reference_id_present?
    render json: { errors: [I18n.t("controller.users.errors.reference_id_required")] }, status: :bad_request unless params.dig(:user, :ids, :reference_id)
  end

  # Sets the user object
  def set_user
    @user = User.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:id)).first
    render json: { errors: [I18n.t("controller.users.errors.not_registered")
] }, status: :not_found if @user.blank?
  end

  # Allows only certain parameters to be saved and updated.
  def user_create_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end

  def user_update_params
    params.require(:user).permit(:first_name, :last_name)
  end

  def set_client
    @client = Client.where(kylas_tenant_id: params["tenantId"]).first
  end
end
