class Mp::UsersController < MpController
  before_action :authenticate_user!, except: [:new, :create]
  before_action :set_client, only: [:create]

  def new
    @user = User.new(role: 'admin')
  end

  def create
    respond_to do |format|
      @user = User.new(role: 'admin')
      @user.assign_attributes(user_params)
      @user.assign_attributes(booking_portal_client: @client)
      if @user.save
        format.html { redirect_to new_mp_user_session_path, notice: 'Successfully registered' }
      else
        format.html { redirect_to new_mp_user_path, alert: @user.errors.full_messages }
      end
    end
  end

  private

  def set_client
    @client = Client.where(company_name: params.dig(:user, :company_name)).first
    if @client.blank?
      @client = Client.new
      @client.assign_attributes(client_params)
    end
    unless @client.save
      respond_to do |format|
        format.json { render json: { errors: @client.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone)
  end

  def client_params
    params.require(:user).permit(:company_name)
  end
end
