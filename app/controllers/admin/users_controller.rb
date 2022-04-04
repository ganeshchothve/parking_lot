class Admin::UsersController < AdminController
  include UsersConcern
  before_action :authenticate_user!, except: %w[resend_confirmation_instructions change_state]
  before_action :set_user, except: %i[index export new create portal_stage_chart channel_partner_performance partner_wise_performance search_by]
  before_action :authorize_resource, except: %w[resend_confirmation_instructions change_state]
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

  def reactivate_account
    @user.update_last_activity!
    @user.expired_at = nil
    respond_to do |format|
      if @user.save
        flash[:notice] = 'User Account reactivated successfully.'
        format.html { redirect_to admin_users_path }
      else
        flash[:alert] = "There was some error while reactivating account. Please contact support for assistance"
        format.html { redirect_to admin_users_path }
      end
    end
  end

  def resend_confirmation_instructions
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.resend_confirmation_instructions
        flash[:notice] = 'Confirmation instructions sent successfully.'
        format.html { redirect_to request.referer || admin_users_path }
      else
        flash[:error] = "Couldn't send confirmation instructions."
        format.html { redirect_to request.referer || admin_users_path }
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
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_users_path(fltrs: params[:fltrs].as_json)
  end

  def print; end

  def new
    @user = User.new(booking_portal_client_id: current_client.id)
    @user.role = params.dig(:user, :role).blank? ? 'user' : params.dig(:user, :role)
    render layout: false
  end

  def confirm_via_otp
    @otp_sent_status = {}
    if request.patch?
      if params[:user].present? && params[:user][:login_otp].present? && @user.authenticate_otp(params[:user][:login_otp], drift: 900)
        @user.confirm unless @user.confirmed?
        @user.iris_confirmation = true
        if current_user.present? && current_user.role?('channel_partner')
          @user.manager_id = current_user.id
          @user.manager_change_reason = "User confirmed using OTP by this channel_partner"
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

  def create
    # sending the role upfront to ensure the permitted_attributes in next step is updated
    message = 'User was successfully created.'
    change_channel_partner_company = false
    query = []
    query << { phone: params.dig(:user, :phone) } if params.dig(:user, :phone).present?
    query << { email: params.dig(:user, :email) } if params.dig(:user, :email).present?
    @user = User.in(role: %w(channel_partner cp_owner)).or(query).first
    if current_user.role?('cp_owner') && params[:user][:role].in?(%w(cp_owner channel_partner)) && @user.present? && !@user.is_active? && @user.channel_partner_id != current_user.channel_partner_id
      @user.assign_attributes(channel_partner_id: current_user.channel_partner_id, role: params[:user][:role], is_active: true)
      message = t('controller.users.create.change_channel_partner_company')
      change_channel_partner_company = true
    end
    create_user unless change_channel_partner_company

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_users_path, notice: message }
        format.json { render json: @user, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
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

  #TO DO - move to SourcingManagerDashboardConcern
  def channel_partner_performance
    interested_project_matcher = {status: {'$in': ["approved"]}}
    dates = params[:dates]
    @interested_project_dates = dates
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    start_date, end_date = @interested_project_dates.split(' - ') if @interested_project_dates.present?
    interested_project_matcher[:created_at] =  {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day } if start_date.present? && end_date.present?
    @leads = Lead.where(Lead.user_based_scope(current_user, params)).filter_by_created_at(dates)
    @site_visits = SiteVisit.where(SiteVisit.user_based_scope(current_user, params)).filter_by_scheduled_on(dates)
    @bookings = BookingDetail.booking_stages.where(BookingDetail.user_based_scope(current_user, params)).filter_by_booked_on(dates)
    if params[:project_ids].present?
      project_ids = params["project_ids"].try(:split, ",").try(:flatten)
      project_ids = Project.where(id: {"$in": project_ids}).distinct(:id)
      @leads = @leads.filter_by_project_ids(project_ids)
      @site_visits = @site_visits.filter_by_project_ids(project_ids)
      @bookings = @bookings.filter_by_project_ids(project_ids)
      interested_project_matcher[:project_id] = {'$in': project_ids} if project_ids.present?
    end
    if params[:channel_partner_id].present?
      @leads = @leads.where(channel_partner_id: params[:channel_partner_id])
      @site_visits = @site_visits.where(channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(channel_partner_id: params[:channel_partner_id])
      channel_partner = ChannelPartner.where(id: params[:channel_partner_id]).first
      interested_project_matcher[:user_id] = {'$in': channel_partner.users.distinct(:id)} if channel_partner.present?
    end
    if params[:manager_id].present?
      @leads = @leads.where(manager_id: params[:manager_id])
      @site_visits = @site_visits.where(manager_id: params[:manager_id])
      @bookings = @bookings.where(manager_id: params[:manager_id])
    end
    # Exclude leads added by non-channel partner accounts in channel partner performance report
    if params[:manager_id].blank? && params[:channel_partner_id].blank?
      @leads = @leads.ne(manager_id: nil)
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @subscribed_count_project_wise = DashboardDataProvider.subscribed_count_project_wise(current_user, interested_project_matcher)
    @leads = @leads.group_by{|p| p.project_id}
    @all_site_visits = @site_visits.group_by{|p| p.project_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.project_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.project_id}
    @pending_site_visits = @site_visits.filter_by_approval_status('pending').group_by{|p| p.project_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.project_id}
    @rejected_site_visits = @site_visits.filter_by_approval_status('rejected').group_by{|p| p.project_id}
    @bookings = @bookings.group_by{|p| p.project_id}
    @projects = params[:project_ids].present? ? Project.filter_by__id(params[:project_ids]) : Project.all
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::ChannelPartnerPerformance.channel_partner_performance_csv(current_user, @projects, @leads, @bookings, @all_site_visits, @site_visits, @pending_site_visits, @approved_site_visits, @rejected_site_visits, @subscribed_count_project_wise, @scheduled_site_visits, @conducted_site_visits).string , filename: "channel_partner_performance-#{Date.today}.xls", type: "application/xls" }
    end
  end

  #TO DO - move to SourcingManagerDashboardConcern
  def partner_wise_performance
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    @leads = Lead.filter_by_created_at(dates).where(Lead.user_based_scope(current_user, params))

    @site_visits = SiteVisit.filter_by_scheduled_on(dates).where(SiteVisit.user_based_scope(current_user, params))
    @bookings = BookingDetail.booking_stages.filter_by_booked_on(dates).where(BookingDetail.user_based_scope(current_user, params))

    @site_visits_manager_ids = @site_visits.distinct(:manager_id).compact
    @booking_detail_manager_ids = @bookings.distinct(:manager_id).compact

    @manager_ids_criteria = partner_wise_filters(@site_visits_manager_ids, @booking_detail_manager_ids, params)

    if params[:project_id].present?
      @leads = @leads.where(project_id: params[:project_id])
      @site_visits = @site_visits.where(project_id: params[:project_id])
      @bookings = @bookings.where(project_id: params[:project_id])
    end
    if params[:channel_partner_id].present?
      @leads = @leads.where(channel_partner_id: params[:channel_partner_id])
      @site_visits = @site_visits.where(channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(channel_partner_id: params[:channel_partner_id])
    else
      @leads = @leads.ne(manager_id: nil)
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @leads = @leads.group_by{|p| p.manager_id}
    @all_site_visits = @site_visits.ne(manager_id: nil).group_by{|p| p.manager_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.manager_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.manager_id}
    @pending_site_visits = @site_visits.filter_by_approval_status('pending').group_by{|p| p.manager_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.manager_id}
    @rejected_site_visits = @site_visits.filter_by_approval_status('rejected').group_by{|p| p.manager_id}
    @bookings = @bookings.group_by{|p| p.manager_id}
    user = params[:channel_partner_id].present? ? ChannelPartner.where(id: params[:channel_partner_id]).first&.users&.cp_owner&.first : current_user
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::PartnerWisePerformance.partner_wise_performance_csv(user, @leads, @bookings, @all_site_visits, @site_visits, @pending_site_visits, @approved_site_visits, @rejected_site_visits, @scheduled_site_visits, @conducted_site_visits, @manager_ids_criteria).string , filename: "partner_wise_performance-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def site_visit_project_wise
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    @site_visits = SiteVisit.filter_by_scheduled_on(dates).where(SiteVisit.user_based_scope(current_user, params))
    @projects = params[:project_ids].present? ? Project.filter_by__id(params[:project_ids]) : Project.filter_by_is_active(true)
    if params[:project_ids].present?
      @site_visits = @site_visits.where(project_id: {"$in": params[:project_ids]})
    elsif
      @site_visits = @site_visits.where(project_id: {"$in": @projects.pluck(:id)})
    end
    if params[:manager_id].present?
      @site_visits = @site_visits.where(manager_id: params[:manager_id])
    end
    if params[:channel_partner_id].present?
      @site_visits = @site_visits.where(channel_partner_id: params[:channel_partner_id])
    end
    if params[:manager_id].blank? && params[:channel_partner_id].blank?
      @site_visits = @site_visits.ne(manager_id: nil)
    end
    @all_site_visits = @site_visits.group_by{|p| p.project_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.project_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.project_id}
    @paid_site_visits = @site_visits.filter_by_status('paid').group_by{|p| p.project_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.project_id}
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::SiteVisitProjectWise.site_visit_project_wise_csv(current_user, @projects, @approved_site_visits, @scheduled_site_visits, @conducted_site_visits, @all_site_visits, @paid_site_visits).string , filename: "site_visit_project_wise_csv-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def site_visit_partner_wise
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?

    @site_visits = SiteVisit.filter_by_scheduled_on(dates).where(SiteVisit.user_based_scope(current_user, params))
    @bookings = BookingDetail.booking_stages.filter_by_booked_on(dates).where(BookingDetail.user_based_scope(current_user, params))

    @site_visits_manager_ids = @site_visits.distinct(:manager_id).compact || []
    @booking_detail_manager_ids = @bookings.distinct(:manager_id).compact || []

    @manager_ids_criteria = partner_wise_filters(@site_visits_manager_ids, @booking_detail_manager_ids, params)

    if params[:project_id].present?
      @site_visits = @site_visits.where(project_id: params[:project_id])
      @bookings = @bookings.where(project_id: params[:project_id])
    end
    if params[:channel_partner_id].present?
      @site_visits = @site_visits.where(channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(channel_partner_id: params[:channel_partner_id])
    else
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @all_site_visits = @site_visits.ne(manager_id: nil).group_by{|p| p.manager_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.manager_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.manager_id}
    @paid_site_visits = @site_visits.filter_by_status('paid').group_by{|p| p.manager_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.manager_id}
    @bookings = @bookings.group_by{|p| p.manager_id}
    user = params[:channel_partner_id].present? ? ChannelPartner.where(id: params[:channel_partner_id]).first&.users&.cp_owner&.first : current_user
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::SiteVisitPartnerWise.site_visit_partner_wise_csv(user, @bookings, @all_site_visits, @approved_site_visits, @scheduled_site_visits, @conducted_site_visits, @paid_site_visits, @manager_ids_criteria).string , filename: "site_visit_partner_wise-#{Date.today}.xls", type: "application/xls" }
    end
  end

  # GET /admin/users/search_by
  #
  def search_by
    @users = User.unscoped.build_criteria params
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
          format.html { redirect_to request.referer, alert: 'Requested partner company not found' }
          format.json { render json: { errors: ['Requested partner company not found'] }, status: :unprocessable_entity }
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
    @user.manager_id = @user.channel_partner&.manager_id if @user.role?('channel_partner') && @user.channel_partner&.manager_id.present?
    @user.manager_id = current_user.id if @user.role?('channel_partner') && current_user.role?('cp')
    if @user.buyer? && current_user.role?('channel_partner')
      @user.manager_id = current_user.id
      @user.referenced_manager_ids ||= []
      @user.referenced_manager_ids += [current_user.id]
    end
  end

  def push_fund_account_on_create_or_change(format, user)
    if user.role.in?(%w(cp_owner channel_partner))
      # Create/Update fund account if found in params
      if user.fund_accounts.blank?
        if params.dig(:user, :fund_accounts, :address).present?
          fund_account = user.fund_accounts.build
          fund_account.assign_attributes(params.dig(:user, :fund_accounts).permit(FundAccountPolicy.new(current_user, fund_account).permitted_attributes))
        end
      else
        fund_account = user.fund_accounts.first
        if params.dig(:user, :fund_accounts).present?
          fund_account.assign_attributes(params.dig(:user, :fund_accounts).permit(FundAccountPolicy.new(current_user, fund_account).permitted_attributes))
        end
      end

      # Create/Update fund account in razorpay if its api is configured
      razorpay_base = Crm::Base.where(domain: ENV_CONFIG.dig(:razorpay, :base_url)).first
      if fund_account && razorpay_base
        if fund_account.new_record?
          razorpay_api, api_log = fund_account.push_in_crm(razorpay_base) if fund_account.is_active?

        elsif fund_account.is_active_changed?
          razorpay_fund_id = fund_account.crm_reference_id(razorpay_base)

          if fund_account.is_active? && razorpay_fund_id.present? && (fund_account.address_changed? || fund_account.address != fund_account.old_address)
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base, true)
            # In case of user updates to old inactive fund account,
            # Call razorpay api again to activate it. As above api call will create the fund account, but as its already present on razorpay in inactive form, it will just return its id & won't update its activeness.
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base) if api_log.present? && api_log.status == 'Success'
          else
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base)
            if razorpay_api.blank? || (api_log.present? && api_log.status == 'Success')
              fund_account.old_address = fund_account.address
            end
          end
        end
      end
    end

    if razorpay_api.blank? || api_log.blank? || api_log.status == 'Success'
      if fund_account.blank? || fund_account.save
        yield
      else
        format.json { render json: {errors: fund_account.errors.full_messages}, status: :unprocessable_entity }
      end
    else
      format.json { render json: {errors: api_log.message}, status: :unprocessable_entity }
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

  def generate_password
    ( ('AaF'..'ZzK').to_a.sample + (0..999).to_a.sample.to_s + '@')
  end

  def partner_wise_filters (site_visit_manager_ids, booking_detail_manager_ids, params = {})

    manager_ids_with_sv_and_booking = site_visit_manager_ids & booking_detail_manager_ids
    manager_ids_with_sv_or_booking = site_visit_manager_ids || booking_detail_manager_ids
    manager_ids_with_sv_and_no_booking = site_visit_manager_ids - booking_detail_manager_ids
    manager_ids_with_booking_and_no_sv = booking_detail_manager_ids - site_visit_manager_ids

    user_ids = if params[:active_walkins] == 'true' && params[:active_bookings] == 'true'
      manager_ids_with_sv_and_booking
    elsif params[:active_walkins] == 'true' && params[:active_bookings] == 'false'
      manager_ids_with_sv_and_no_booking
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == 'true'
      manager_ids_with_booking_and_no_sv
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == 'false'
      User.nin(id: manager_ids_with_sv_or_booking).distinct(:id)
    elsif params[:active_walkins] == 'true' && params[:active_bookings] == ''
      User.in(id: site_visit_manager_ids).distinct(:id)
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == ''
      User.nin(id: @site_visit_manager_ids).distinct(:id)
    elsif params[:active_walkins] == '' && params[:active_bookings] == 'true'
      User.in(id: @booking_detail_manager_ids).distinct(:id)
    elsif params[:active_walkins] == '' && params[:active_bookings] == 'false'
      User.nin(id: @booking_detail_manager_ids).distinct(:id)
    else
      User.filter_by_role(%w(cp_owner channel_partner)).distinct(:id)
    end

    manager_ids = {id: user_ids}
    manager_ids
  end

end
