module UsersConcern
  extend ActiveSupport::Concern

  def update_password
    render layout: false, template: 'users/update_password'
  end

  def reactivate_account
    @user.update_last_activity!
    @user.expired_at = nil
    respond_to do |format|
      if @user.save
        flash[:notice] = I18n.t("controller.users.notice.reactivated_account")
        format.html { redirect_to admin_users_path }
      else
        flash[:alert] = I18n.t("controller.users.alert.account_reactivation")
        format.html { redirect_to admin_users_path }
      end
    end
  end

  def resend_confirmation_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.resend_confirmation_instructions
        flash[:notice] = I18n.t("controller.users.notice.confirmation_sent")
        format.html { redirect_to request.referer || admin_users_path }
      else
        flash[:error] = I18n.t("controller.users.errors.could_not_send_confirmation")
        format.html { redirect_to request.referer || admin_users_path }
      end
    end
  end

  def resend_password_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.send_reset_password_instructions
        flash[:notice] = I18n.t("controller.users.notice.resend_password_sent")
        format.html { redirect_to admin_users_path }
      else
        flash[:error] = I18n.t("controller.users.errors.could_not_send_reset_password")
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
          SelldoLeadUpdater.perform_async(@user.leads.first&.id, {stage: 'confirmed'}) if @user.buyer?
          email_template = ::Template::EmailTemplate.find_by(name: "account_confirmation")
          email = Email.create!({
            booking_portal_client_id: @user.booking_portal_client_id,
            body: ERB.new(@user.booking_portal_client.email_header).result( binding) + email_template.parsed_content(@user) + ERB.new(@user.booking_portal_client.email_footer).result( binding ),
            subject: email_template.parsed_subject(@user),
            recipients: [ @user ],
            cc: @user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
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
      UserExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json, timezone: Time.zone.name)
    end
    flash[:notice] = I18n.t("global.export_scheduled")
    redirect_to admin_users_path(fltrs: params[:fltrs].as_json)
  end

  def print; end

  def confirm_via_otp
    @otp_sent_status = {}
    if request.patch?
      if params[:user].present? && params[:user][:login_otp].present? && @user.authenticate_otp(params[:user][:login_otp], drift: 900)
        @user.confirm unless @user.confirmed?
        @user.iris_confirmation = true
        if current_user.present? && current_user.role?('channel_partner')
          @user.manager_id = current_user.id
          @user.manager_change_reason = I18n.t("controller.users.notice.confirmed_via_otp")
        end
        @user.save
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

  def block_lead
    @referenced_managers = User.in(id: @user.referenced_manager_ids).all
    render layout: false
  end

  def unblock_lead
    respond_to do |format|
      if @user.unblock_lead!
        format.html{ redirect_to request.referrer || admin_users_path, notice: I18n.t("controller.users.notice.unqualified") }
        format.json{ render json: {notice: I18n.t("controller.users.notice.unqualified")}, status: :created }
      else
        format.html{ redirect_to request.referrer || admin_users_path, alert: I18n.t("controller.users.alert.unqalified") }
        format.json{ render json: {alert: I18n.t("controller.users.alert.unqalified")}, status: :unprocessable_entity }
      end
    end
  end

  # GET /admin/users/search_by
  #
  def search_by
    @users = User.unscoped.build_criteria params
    @users = @users.where(User.user_based_scope(current_user))
    @users = @users.paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
  end

  def move_to_next_state
    respond_to do |format|
      if @user.move_to_next_state!(params[:status])
        format.html{ redirect_to request.referrer || dashboard_url, notice: I18n.t("controller.users.move_to_next_state.#{@user.role}.#{@user.status}", name: @user.name.titleize) }
        format.json { render json: { message: I18n.t("controller.users.move_to_next_state.#{@user.role}.#{@user.status}", name: @user.name.titleize) }, status: :ok }
      else
        format.html{ redirect_to request.referrer || dashboard_url, alert: @user.errors.full_messages.uniq }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  # For changing the state of channel_partner user accounts
  def change_state
    respond_to do |format|
      @user.assign_attributes(event: params.dig(:user, :user_status_in_company_event), rejection_reason: params.dig(:user, :rejection_reason))
      user_current_status_in_company = @user.user_status_in_company

      if user_current_status_in_company == 'pending_approval' && @user.event == 'active'
        @channel_partner = ChannelPartner.where(id: params.dig(:user, :channel_partner_id)).first
        unless @channel_partner
          format.html { redirect_to request.referer, alert: I18n.t("controller.users.alert.company_not_found") }
          format.json { render json: { errors: [I18n.t("controller.users.alert.company_not_found")] }, status: :unprocessable_entity }
          return
        end
      end

      if @user.save
        format.html { redirect_to (request.referrer.include?('add_user_account') ? root_path : request.referrer), notice: t("controller.users.status_in_company_message.#{user_current_status_in_company}_to_#{@user.user_status_in_company}") }
      else
        format.html { redirect_to request.referer, alert: @user.errors.full_messages.uniq }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def generate_password
    ( ('AaF'..'ZzK').to_a.sample + (0..999).to_a.sample.to_s + '@')
  end

end
