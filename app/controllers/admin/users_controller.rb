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

  def update_password
    render layout: false
  end


  def resend_confirmation_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.resend_confirmation_instructions
        @user.send_registration_sms
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

  def show
    @project_units = @user.project_units.paginate(page: params[:page] || 1, per_page: 15)
    @receipts = @user.receipts.paginate(page: params[:page] || 1, per_page: 15)
  end

  def new
    @user = User.new(booking_portal_client_id: current_client.id)
    @user.role = params[:role].blank? ? "user" : params[:role]
    render layout: false
  end

  def edit
    render layout: false
  end

  def create
    # sending the role upfront to ensure the permitted_attributes in next step is updated
    @user = User.new(booking_portal_client_id: current_client.id, role: params[:user][:role])
    @user.assign_attributes(permitted_attributes(@user))
    @user.manager_id = current_user.id if @user.role?('channel_partner') && current_user.role?('cp')

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_path, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    @user.assign_attributes(permitted_attributes(@user))
    respond_to do |format|
      if @user.save
        if current_user == @user && permitted_attributes(@user).keys.include?("password")
          bypass_sign_in(@user)
        end
        format.html { redirect_to edit_admin_user_path(@user), notice: 'User Profile updated successfully.' }
        format.json { render json: @user }
      else
        format.html { render :edit }
        format.json { render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_user
    if params[:id].blank?
      @user = current_user
    else
      @user = User.find(params[:id])
    end
  end

  def authorize_resource
    if ['index', 'export', 'export_cp_report', 'export_cp_lead_report'].include?(params[:action])
      authorize User
    elsif params[:action] == "new" || params[:action] == "create"
      if params[:role].present?
        authorize User.new(role: params[:role], booking_portal_client_id: current_client.id)
      else
        authorize User.new(booking_portal_client_id: current_client.id)
      end
    else
      authorize @user
    end
  end

  def apply_policy_scope
    custom_scope = User.where(User.user_based_scope(current_user, params))
    User.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
