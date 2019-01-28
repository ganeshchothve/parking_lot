class Api::V1::UsersController < ApisController
  before_action :authenticate_request
  before_action :set_user, except: :create
  before_action :erp_id_present?

  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  def update
    @user.assign_attributes(user_params)
    if @user.save
      render json: @user, status: :ok
    else
      render json: @user.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  def portal_stage
    if @portal_stage.update(portal_stage_attributes: { stage: params[:user][:portal_stage][:stage], updated_at: params[:user][:portal_stage][:updated_at] }) && @user.update(user_params)
      render json: @user, status: :ok
    else
      render json: @user.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  private

  def erp_id_present?
    true if params[:user][:erp_id]
  end

  def set_user
    @user = User.where(erp_id: params[:user][:erp_id]).first
    render json: { status: 'error', code: 4000, message: 'User is not registered.' } if @user.blank? # TO DO EROR mesg prob
  end

  def user_params
    params.fetch(:user, {}).permit(:erp_id, :lead_id, :first_name, :last_name, :email, :phone, :confirmed_at, :role, :booking_portal_client_id, utm_params: %i[campaign source sub_source medium term content], portal_stage: %i[stage updated_at])
  end
end
