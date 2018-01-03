# TODO: replace all messages & flash messages
class UserKycsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_kyc, only: [:show, :edit, :update, :destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout 'dashboard'

  def index
    @user_kycs = UserKyc.all
  end

  def new
    @user_kyc = UserKyc.new(user: current_user)
  end

  def edit
  end

  def create
    @user_kyc = UserKyc.new(permitted_attributes(UserKyc.new))
    @user_kyc.user = current_user

    respond_to do |format|
      if @user_kyc.save
        format.html { redirect_to user_kycs_path, notice: 'User kyc was successfully created.' }
        format.json { render :show, status: :created, location: @user_kyc }
      else
        format.html { render :new }
        format.json { render json: @user_kyc.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user_kyc.update(permitted_attributes(@user_kyc))
        format.html { redirect_to user_kycs_path, notice: 'User kyc was successfully updated.' }
        format.json { render :show, status: :ok, location: @user_kyc }
      else
        format.html { render :edit }
        format.json { render json: @user_kyc.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_user_kyc
    @user_kyc = UserKyc.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
    elsif params[:action] == "new"
      authorize UserKyc.new
    elsif params[:action] == "create"
      authorize UserKyc.new(permitted_attributes(UserKyc.new))
    else
      authorize @user_kyc
    end
  end

  def apply_policy_scope
    # TODO: handle this for non current_user logins
    UserKyc.with_scope(UserKyc.where(user_id: current_user.id)) do
      yield
    end
  end
end
