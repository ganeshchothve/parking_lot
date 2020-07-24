class Admin::UsersController < AdminController
  include UsersConcern
  before_action :authenticate_user!
  before_action :set_user, except: %i[index export new create portal_stage_chart]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index export]

  layout :set_layout

  # Show
  # show defined in UsersConcern
  # GET /admin/users/:id

  # Edit
  # edit defined in UsersConcern
  # GET /admin/users/:id/edit

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

  def resend_confirmation_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.resend_confirmation_instructions
        flash[:notice] = 'Confirmation instructions sent successfully.'
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
        flash[:notice] = 'Reset password instructions sent successfully.'
        format.html { redirect_to admin_users_path }
      else
        flash[:error] = "Couldn't send Reset password instructions."
        format.html { redirect_to admin_users_path }
      end
    end
  end

  def confirm_user
    @user.temporary_password = generate_password * 2
    @user.assign_attributes(confirmed_by: current_user, confirmed_at: DateTime.now, password: @user.temporary_password, password_confirmation: @user.password_confirmation)
    respond_to do |format|
      format.html do
        if @user.save
          SelldoLeadUpdater.perform_async(@user.id, {stage: 'confirmed'})
          email_template = ::Template::EmailTemplate.find_by(name: "account_confirmation")
          email = Email.create!({
            booking_portal_client_id: @user.booking_portal_client_id,
            body: ERB.new(@user.booking_portal_client.email_header).result( binding) + email_template.parsed_content(@user) + ERB.new(@user.booking_portal_client.email_footer).result( binding ),
            subject: email_template.parsed_subject(@user),
            recipients: [ @user ],
            triggered_by_id: @user.id,
            triggered_by_type: @user.class.to_s
          })
          email.sent!
          if @user.buyer? && policy([:admin, @user]).block_lead?
            redirect_to admin_users_path("remote-state": block_lead_admin_user_path(@user , notice: t('controller.users.account_confirmed_and_block_lead')))
          else
            redirect_to request.referrer || dashboard_url, notice: t('controller.users.account_confirmed')
          end
        else
          redirect_to request.referrer || dashboard_url, alert: t('controller.users.cannot_confirm_user')
        end
      end
    end
  end

  def export
    if Rails.env.development?
      UserExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      UserExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path(fltrs: params[:fltrs].as_json)
  end

  def print; end

  def new
    @user = User.new(booking_portal_client_id: current_client.id)
    @user.role = params[:role].blank? ? 'user' : params[:role]
    render layout: false
  end

  def confirm_via_otp
    @otp_sent_status = {}
    if request.patch?
      if params[:user].present? && params[:user][:login_otp].present? && @user.authenticate_otp(params[:user][:login_otp], drift: 60)
        @user.confirm unless @user.confirmed?
      end
    else
      @otp_sent_status = @user.send_otp
      if Rails.env.development?
        Rails.logger.info "---------------- #{@user.otp_code} ----------------"
      end
    end
    respond_to do |format|
      if @otp_sent_status[:status] || @user.save
        format.html { render layout: false }
        format.json { render json: @user }
      else
        format.html { render layout: false }
        format.json { render json: { errors: @user.errors.full_messages }, status: 422 }
      end
    end
  end

  def create
    # sending the role upfront to ensure the permitted_attributes in next step is updated
    @user = User.new(booking_portal_client_id: current_client.id, role: params[:user][:role])
    @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))
    @user.manager_id = current_user.id if @user.role?('channel_partner') && current_user.role?('cp')
    if @user.buyer? && current_user.role?('channel_partner')
      @user.manager_id = current_user.id
      @user.referenced_manager_ids ||= []
      @user.referenced_manager_ids += [current_user.id]
    end

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

  def update
    @user.assign_attributes(permitted_attributes([current_user_role_group, @user]))
    respond_to do |format|
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

  def block_lead
    @referenced_managers = User.in(id: @user.referenced_manager_ids).all
    render layout: false
  end

  def unblock_lead
    respond_to do |format|
      if @user.unblock_lead!
        format.html{ redirect_to request.referrer || admin_users_path, notice: "Lead unqualified successfully" }
        format.json{ render json: {notice: "Lead unqualified successfully"}, status: :created }
      else
        format.html{ redirect_to request.referrer || admin_users_path, alert: "Lead cannot be unqualified" }
        format.json{ render json: {alert: "Lead cannot be unqualified"}, status: :unprocessable_entity }
      end
    end
  end

  #
  # GET /admin/users/portal_stage_chart
  #
  # This method is used in admin dashboard
  #
  def portal_stage_chart
    @data = DashboardData::AdminDataProvider.user_block
  end

  def send_payment_link
    respond_to do |format|
      format.html do
        @user.send_payment_link
        redirect_to admin_users_url, notice: t('controller.users.send_payment_link')
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

  def authorize_resource
    if %w[index export portal_stage_chart].include?(params[:action])
      authorize [current_user_role_group, User]
    elsif params[:action] == 'new' || params[:action] == 'create'
      if params[:role].present?
        authorize [current_user_role_group, User.new(role: params[:role], booking_portal_client_id: current_client.id)]
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

  def generate_password
    ( ('AaF'..'ZzK').to_a.sample + (0..999).to_a.sample.to_s + '@')
  end
end
