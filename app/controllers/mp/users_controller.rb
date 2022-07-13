class Mp::UsersController < ApplicationController
  before_action :authenticate_user!, except: [:signup, :register]
  before_action :set_client, only: [:register]

  def signup
    @user = User.new(role: 'admin')
  end

  def register
    respond_to do |format|
      @user = User.new(role: 'admin')
      @user.assign_attributes(user_params)
      @user.assign_attributes(booking_portal_client: @client)
      if @user.save
        format.html { redirect_to new_user_session_path(namespace: 'mp'), notice: 'Successfully registered' }
      else
        format.html { redirect_to signup_mp_users_path(namespace: 'mp'), alert: @user.errors.full_messages }
      end
    end
  end

  private

  def set_client
    @client = Client.where(name: params.dig(:user, :name)).first
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
    params.require(:user).permit(:name)
  end
end
