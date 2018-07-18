class Admin::UsersController < AdminController
  before_action :authenticate_user!
  before_action :set_user, except: [:index, :export, :new, :create, :export_cp_report, :export_cp_lead_report]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export, :export_cp_report, :export_cp_lead_report]

  layout :set_layout

  def index
    @users = User.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_user_path(params[:fltrs][:_id])
    else
      @users = @users.paginate(page: params[:page] || 1, per_page: 15)
    end
  end

  def resend_confirmation_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.resend_confirmation_instructions
        flash[:notice] = "Confirmation instructions sent successfully."
        format.html { redirect_to admin_users_path }
      else
        flash[:error] = "Couldn't send confirmation instructions."
        format.html { redirect_to admin_users_path }
      end
    end
  end

  def resend_password_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.send_reset_password_instructions
        flash[:notice] = "Reset password instructions sent successfully."
        format.html { redirect_to admin_users_path }
      else
        flash[:error] = "Couldn't send Reset password instructions."
        format.html { redirect_to admin_users_path }
      end
    end
  end

  def export
    if Rails.env.development?
      UserExportWorker.new.perform(current_user.email)
    else
      UserExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path
  end

  def export_cp_report
    if Rails.env.development?
      ChannelPartnerBookingDetailsExportWorker.new.perform(current_user.email)
    else
      ChannelPartnerBookingDetailsExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path
  end

  def export_cp_lead_report
    if Rails.env.development?
      ChannelPartnerLeadDetailsExportWorker.new.perform(current_user.email)
    else
      ChannelPartnerLeadDetailsExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path
  end

  def show
    @project_units = @user.project_units.paginate(page: params[:page] || 1, per_page: 15)
  end

  def new
    @user = User.new
    @user.role = params[:role].blank? ? "user" : params[:role]
  end

  def edit
  end

  def create
    @user = User.new
    @user.assign_attributes(permitted_attributes(@user))

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_path, notice: 'User was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    @user.assign_attributes(permitted_attributes(@user))
    respond_to do |format|
      if @user.save
        format.html { redirect_to edit_admin_user_path(@user), notice: 'User Profile updated successfully.' }
      else
        format.html { render :edit }
      end
    end
  end

  private
  def set_user
    @user = User.find(params[:id])
  end

  def authorize_resource
    if ['index', 'export', 'export_cp_report', 'export_cp_lead_report'].include?(params[:action])
      authorize User
    elsif params[:action] == "new" || params[:action] == "create"
      if params[:role].present?
        authorize User.new(role: params[:role])
      else
        authorize User.new
      end
    else
      authorize @user
    end
  end

  def apply_policy_scope
    custom_scope = User.all.criteria
    if current_user.role?('channel_partner')
      custom_scope = custom_scope.in(referenced_channel_partner_ids: current_user.id).in(role: User.buyer_roles)
    elsif current_user.role?('crm')
      custom_scope = custom_scope.in(role: User.buyer_roles)
    elsif current_user.role?('sales')
      custom_scope = custom_scope.in(role: User.buyer_roles)
    elsif current_user.role?('cp')
      custom_scope = custom_scope.or([{role: 'user', channel_partner_id: {"$exists": true}}, {role: "channel_partner"}])
    end
    User.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
