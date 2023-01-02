class Admin::UsersController < AdminController
  include UsersConcern
  include FundAccountsConcern
  include UserReportsConcern

  before_action :authenticate_user!, except: %w[resend_confirmation_instructions change_state signup register]
  before_action :set_user, except: %i[index export new create portal_stage_chart channel_partner_performance partner_wise_performance search_by signup register]
  before_action :validate_player_ids, only: %i[update_player_ids]
  before_action :authorize_resource, except: %w[resend_confirmation_instructions change_state signup register sync_kylas_users]
  around_action :apply_policy_scope, only: %i[index export]
  before_action :set_client, only: [:register]
  before_action :fetch_kylas_users, only: %i[new edit]

  layout :set_layout

  # Update Password
  # update password defined in UsersConcern
  # GET /admin/users/:id/update_password

  def signup
    @client = Client.new
    @user = User.new(role: 'admin')
  end

  def register
    respond_to do |format|
      @user.skip_confirmation_notification!
      if @user.save
        @user.confirm
        format.html { redirect_to (session[:previous_url] || new_user_session_path), notice: 'Successfully registered' }
      else
        flash.now[:alert] = @user.errors.full_messages
        format.html { render :signup }
      end
    end
  end

  def index
    @users = User.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present? && policy([current_user_role_group, User.where(booking_portal_client_id: current_client.id, id: params.dig(:fltrs, :_id)).first || User.new(booking_portal_client_id: current_client.id)]).show?
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
    if current_user.role?('cp_owner')
      @user.channel_partner_id = current_user.channel_partner_id
    else
      @user.channel_partner_id = params.dig(:user, :channel_partner_id)
    end
    render layout: false
  end

  def create
    # sending the role upfront to ensure the permitted_attributes in next step is updated
    create_user
    respond_to do |format|
      if @user.save
        if @user.role.in?(%w(channel_partner cp_owner)) && current_user.role.in?(%w(cp_owner admin))
          @user.active!(true)
        end
        format.html { redirect_to admin_users_path, notice: I18n.t("controller.users.notice.created") }
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
      update_masked_email_and_phone_if_present
      push_fund_account_on_create_or_change(format, @user) do
        @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))
        if @user.save
          if current_user == @user && permitted_attributes([current_user_role_group, @user]).key?('password')
            bypass_sign_in(@user)
          end
          _path = params.dig(:user, :is_first_login).present? ? home_path(current_user) : edit_admin_user_path(@user)
          format.html { redirect_to _path, notice: I18n.t("controller.users.notice.profile_updated") }
          format.json { render json: @user }
        else
          if params.dig(:user, :is_first_login).present?
            format.html { redirect_to reset_password_after_first_login_admin_user_path(@user), alert: @user.errors.full_messages }
          else
            format.html { render :edit }
          end
          format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      end
    end
  end

  def update_player_ids
    respond_to do |format|
      @user.assign_attributes(user_notification_token_params)
      if @user.save
        player_id = params.dig(:user, :user_notification_tokens_attributes, :"0", :token)
        @user.update_onesignal_external_user_id(player_id) if player_id.present?
        format.html { redirect_to edit_admin_user_path(@user), notice: I18n.t("controller.users.notice.updated") }
        format.json { render json: { user: @user.as_json, message: I18n.t("controller.users.notice.updated")}, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def approve_reject_company_user
    @channel_partner = ChannelPartner.where(id: @user.temp_channel_partner_id).first
    unless @channel_partner.present?
      redirect_to admin_users_path(fltrs: {user_status_in_company: 'pending_approval'}), alert: "#{ChannelPartner.model_name.human} not found"
    end
    render layout: false
  end

  private

  def set_user
    @user = if params[:crm_client_id].present? && params[:id].present?
              find_user_with_reference_id(params[:crm_client_id], params[:id])
            elsif params[:id].present?
              User.where(booking_portal_client_id: current_client.try(:id), id: params[:id]).first || User.where(booking_portal_client_id: current_client.try(:id), lead_id: params[:id]).first || User.where(selected_client_id: current_client.try(:id), id: params[:id]).first
            else
              current_user
            end
    redirect_to root_path, alert: t('controller.users.set_user_missing') if @user.blank?
  end

  def set_client
    @client = Client.new
    @client.assign_attributes(client_params)
    @client.assign_attributes(booking_portal_domains: ["#{@client.id}.#{ENV_CONFIG[:client_default_domain]}"]) if params.dig(:user, :booking_portal_domains).reject(&:blank?).blank?
    if cp_marketplace_app?
      @client.assign_attributes(industry: 'generic')
    elsif re_marketplace_app?
      @client.assign_attributes(industry: 'real_estate')
    end
    @user = User.new(role: 'admin')
    @user.assign_attributes(user_params)
    @user.assign_attributes(booking_portal_client: @client, tenant_owner: true)
    if @user.valid? && @client.save
      superadmin_users = User.where(role: 'superadmin')
      superadmin_users.update_all(client_ids: Client.pluck(:id))
    else
      respond_to do |format|
        @client.errors.delete(:users)
        flash.now[:alert] = @client.errors.full_messages + @user.errors.full_messages
        format.html { render :signup and return }
      end
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation)
  end

  def client_params
    params.require(:user).permit(:name, :sender_email, booking_portal_domains: [])
  end

  def validate_player_ids
    player_id = params.dig(:user, :user_notification_tokens_attributes, :"0", :token)
    is_player_id_exists = @user.user_notification_tokens.where(token: player_id).present?
    if is_player_id_exists
      respond_to do |format|
        format.html { redirect_to edit_admin_user_path(@user), notice: I18n.t("controller.users.notice.updated") }
        format.json { render json: { user: @user.as_json, message: 'User updated successfully'}, status: :ok }
      end
    end
  end

  def user_notification_token_params
    params.require(:user).permit(user_notification_tokens_attributes: [:token, :os, :device])
  end

  def find_user_with_reference_id crm_id, reference_id
    _crm = Crm::Base.where(id: crm_id, booking_portal_client_id: current_client.id).first
    _user = User.where("third_party_references.crm_id": _crm.try(:id), "third_party_references.reference_id": reference_id, booking_portal_client_id: current_client.id).first
    _user
  end

  def create_user
    @user = User.new(booking_portal_client_id: current_client.id, role: params[:user][:role])
    @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))

    # For channel parnter & cp owners
    if @user.role.in?(%w(channel_partner cp_owner))
      if current_user.role.in?(%w(cp_owner admin))
        @user.manager_id = @user.channel_partner&.manager_id if @user.channel_partner&.manager_id.present?
        @user.project_ids = @user.channel_partner&.project_ids if @user.channel_partner&.project_ids.present?
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

  def update_masked_email_and_phone_if_present
    if @user.maskable_field?(current_user)
      params[:user].delete :phone if params.dig(:user, :phone).blank?
      params[:user].delete :email if params.dig(:user, :email).blank?
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

  def fetch_kylas_users
    @kylas_users = Kylas::FetchUsers.new(current_user).call
  end

end
