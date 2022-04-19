class Admin::UsersController < AdminController
  include UsersConcern
  include FundAccountsConcern
  include UserReportsConcern

  before_action :authenticate_user!, except: %w[resend_confirmation_instructions change_state]
  before_action :set_user, except: %i[index export new create portal_stage_chart channel_partner_performance partner_wise_performance search_by]
  before_action :authorize_resource, except: %w[resend_confirmation_instructions change_state]
  around_action :apply_policy_scope, only: %i[index export]

  layout :set_layout

  # Update Password
  # update password defined in UsersConcern
  # GET /admin/users/:id/update_password

  def index
    @users = User.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_user_path(params[:fltrs][:_id])
    else
      @users = @users.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
  end

  def show
    @project_units = @user.project_units.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @booking_details = @user.booking_details.paginate(page: params[:page], per_page: params[:per_page])
    @receipts = @user.receipts.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @referrals = @user.referrals.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'admin/users/show' }
      format.json
    end
  end

  def new
    @user = User.new(booking_portal_client_id: current_client.id)
    @user.role = params.dig(:user, :role).blank? ? 'user' : params.dig(:user, :role)
    render layout: false
  end

  def create
    # sending the role upfront to ensure the permitted_attributes in next step is updated
    create_user
    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_path, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      push_fund_account_on_create_or_change(format, @user) do
        @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))
        if @user.save
          if current_user == @user && permitted_attributes([current_user_role_group, @user]).key?('password')
            bypass_sign_in(@user)
          end
          format.html { redirect_to edit_admin_user_path(@user), notice: 'User Profile updated successfully.' }
          format.json { render json: @user }
        else
          format.html { render :edit }
          format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def set_user
    @user = if params[:crm_client_id].present? && params[:id].present?
              find_user_with_reference_id(params[:crm_client_id], params[:id])
            elsif params[:id].present?
              User.where(id: params[:id]).first || User.where(lead_id: params[:id]).first
            else
              current_user
            end
    redirect_to root_path, alert: t('controller.users.set_user_missing') if @user.blank?
  end

  def find_user_with_reference_id crm_id, reference_id
    _crm = Crm::Base.where(id: crm_id).first
    _user = User.where("third_party_references.crm_id": _crm.try(:id), "third_party_references.reference_id": reference_id ).first
    _user
  end

  def create_user
    @user = User.new(booking_portal_client_id: current_client.id, role: params[:user][:role])
    @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))

    # For channel parnter & cp owners
    if @user.role.in?(%w(channel_partner cp_owner))
      if current_user.role?('cp_owner')
        @user.user_status_in_company = 'active'
        @user.manager_id = @user.channel_partner&.manager_id if @user.channel_partner&.manager_id.present?
      elsif current_user.role?('cp')
        @user.manager_id = current_user.id
      end
    end

    # For buyers
    if @user.buyer? && current_user.role?('channel_partner')
      @user.manager_id = current_user.id
      @user.referenced_manager_ids ||= []
      @user.referenced_manager_ids += [current_user.id]
    end
  end

  def authorize_resource
    if %w[index export portal_stage_chart channel_partner_performance partner_wise_performance search_by].include?(params[:action])
      authorize [current_user_role_group, User]
    elsif params[:action] == 'new' || params[:action] == 'create'
      if params.dig(:user, :role).present?
        authorize [current_user_role_group, User.new(role: params.dig(:user, :role), booking_portal_client_id: current_client.id)]
      else
        authorize [current_user_role_group, User.new(booking_portal_client_id: current_client.id)]
      end
    else
      authorize [current_user_role_group, @user]
    end
  end

  def apply_policy_scope
    custom_scope = User.where(User.user_based_scope(current_user, params))
    User.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

end
