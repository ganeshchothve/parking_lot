# TODO: replace all messages & flash messages
class UserKycsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_user_kyc, only: [:show, :edit, :update, :destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout :set_layout

  def index
    @user_kycs = UserKyc.paginate(page: params[:page] || 1, per_page: 15)
  end

  def new
    if @user.user_kyc_ids.blank?
      @user_kyc = UserKyc.new(creator: current_user, user: @user, first_name: @user.first_name, last_name: @user.last_name, email: @user.email, phone: @user.phone)
    else
      @user_kyc = UserKyc.new(creator: current_user, user: @user)
    end
  end

  def edit
  end

  def create
    @user_kyc = UserKyc.new(permitted_attributes(UserKyc.new))
    @user_kyc.user = @user
    @user_kyc.creator = current_user

    respond_to do |format|
      if @user_kyc.save
        SFDC::UserKycPusher.execute(@user_kyc)
        format.html { redirect_to home_path(current_user), notice: 'User kyc was successfully created.' }
        format.json { render json: @user_kyc, status: :created, location: @user_kyc }
      else
        format.html { render :new }
        format.json { render json: {errors: @user_kyc.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user_kyc.update(permitted_attributes(@user_kyc))
        format.html { redirect_to home_path(current_user), notice: 'User kyc was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end
  
  def export
    if Rails.env.development?
      UserKycExportWorker.new.perform(current_user.email)
    else
      UserKycExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_user_requests_path
  end

  private
  def set_user
    @user = (params[:user_id].present? ? User.find(params[:user_id]) : current_user)
  end

  def set_user_kyc
    @user_kyc = UserKyc.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
      authorize UserKyc
    elsif params[:action] == "new"
      authorize UserKyc.new(user: @user)
    elsif params[:action] == "create"
      authorize UserKyc.new(permitted_attributes(UserKyc.new))
    else
      authorize @user_kyc
    end
  end

  def apply_policy_scope
    custom_scope = UserKyc.all.criteria
    if current_user.role?('admin') || current_user.role?('crm') || current_user.role?('sales') || current_user.role?('cp')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      end
    elsif current_user.role?('channel_partner')
      if params[:user_id].present?
        custom_scope = custom_scope.where(user_id: params[:user_id])
      else
        custom_scope = custom_scope.where(user_id: current_user.id)
      end
    else
      custom_scope = custom_scope.where(user_id: current_user.id)
    end
    UserKyc.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
