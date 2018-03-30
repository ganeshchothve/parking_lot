class Admin::UsersController < AdminController
  before_action :authenticate_user!
  before_action :set_user, except: [:index, :export, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @users = User.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_user_path(params[:fltrs][:_id])
    else
      @users = @users.paginate(page: params[:page] || 1, per_page: 15)
    end
  end

  def export
    if Rails.env.development?
      ChannelPartnerExportWorker.new.perform(current_user.email)
    else
      ChannelPartnerExportWorker.perform_async(current_user.email)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path
  end

  def show
    @project_units = @user.project_units.paginate(page: params[:page] || 1, per_page: 15)
  end

  def new
    @user = User.new
    if params[:role].present?
      @user.role = params[:role]
    end
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
    if params[:action] == "index" || params[:action] == "export"
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
      custom_scope = custom_scope.in(referenced_channel_partner_ids: current_user.id).where(role: 'user')
    elsif current_user.role?('crm')
      custom_scope = custom_scope.where(role: 'user')
    end
    User.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
