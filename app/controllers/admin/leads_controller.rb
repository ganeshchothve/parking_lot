class Admin::LeadsController < AdminController
  before_action :authenticate_user!
  before_action :set_lead, except: %i[index new export search_by search_inventory new_kylas_associated_lead deal_associated_contact_details create_kylas_associated_lead new_kylas_lead create_kylas_lead]
  before_action :authorize_resource
  before_action :set_sales_user, only: :assign_sales
  around_action :apply_policy_scope, only: %i[index search_inventory]
  include Kylas::LeadCreationConcern

  def new
    attrs = {}
    if params[:user_id].present?
      @user = User.where(id: params[:user_id]).first
      attrs = @user.as_json(only: %w(first_name last_name email phone))
    elsif params[:lead_id].present?
      @existing_lead = Lead.where(id: params[:lead_id]).first
    end
    if params[:project_id].present?
      attrs[:project_id] = params[:project_id]
    elsif Project.count == 1
      attrs[:project_id] = Project.first.id
    end
    @lead = Lead.new(attrs)
    @lead.site_visits.build if params[:walkin].present?
    render layout: false
  end

  def index
    @leads = Lead.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_lead_path(params[:fltrs][:_id])
    else
      @leads = @leads.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
  end

  def show
    @booking_details = @lead.booking_details.paginate(page: params[:page], per_page: params[:per_page])
    @receipts = @lead.receipts.order('created_at DESC').paginate(page: params[:page], per_page: params[:per_page])
    @notes = FetchLeadData.fetch_notes(@lead.lead_id, @lead.user.booking_portal_client)
  end

  def edit
    render layout: false
  end

  def export
    if Rails.env.development?
      LeadExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      LeadExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json, timezone: Time.zone.name)
    end
    flash[:notice] = I18n.t("global.export_scheduled")
    redirect_to admin_leads_path(fltrs: params[:fltrs].as_json)
  end

  def update
    respond_to do |format|
      if @lead.update(permitted_attributes([:admin, @lead]))
        format.html { redirect_to admin_leads_path, notice: I18n.t("controller.leads.notice.updated") }
      else
        format.html { render :edit }
        format.json { render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def sync_notes
    @lead.remarks = FetchLeadData.fetch_notes(@lead.lead_id, @lead.user.booking_portal_client)
    @lead.save
    respond_to do |format|
      format.js
    end
  end

  def send_payment_link
    respond_to do |format|
      format.html do
        @lead.send_payment_link(params[:booking_detail_id])
        redirect_to request.referer, notice: t('controller.users.send_payment_link')
      end
    end
  end

  # GET /admin/leads/search_by
  #
  def search_by
    @leads = Lead.unscoped.build_criteria params
    @leads = @leads.where(Lead.user_based_scope(current_user))
    @leads = @leads.paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
  end

  def assign_sales
    if @lead.may_assign_sales?(params[:sales_id])
      if @lead.assign_manager(params[:sales_id])
        @lead.current_site_visit&.set(sales_id: params[:sales_id])
        flash.now[:notice] = I18n.t("controller.leads.notice.assigned_to", name1: @lead.name, name2: @sales.name)
      else
        flash.now[:alert] = I18n.t("controller.leads.errors.failed_to_assign", name: "#{@lead.name}")
      end
    else
      flash.now[:alert] = I18n.t("controller.leads.errors.failed_to_assign", name: "#{@lead.name}")
    end
  end

  def reassign_lead
    render layout: false
  end

  def reassign_sales
    @sales = User.where(id: params.dig(:lead, :closing_manager_id), role: 'sales').first
    respond_to do |format|
      if @sales.present?
        if @lead.assign_manager(params.dig(:lead, :closing_manager_id), @lead.closing_manager_id)
          message = I18n.t("controller.leads.notice.assigned_to", name1: @lead.name, name2: @sales.name)
          format.html { redirect_to request.referrer || dashboard_url, notice: message }
          format.json { render json: { message: message }, status: :ok }
        else
          message = I18n.t("controller.leads.notice.not_assigned_to", name1: @lead.name, name2: @sales.name)
          format.html{ redirect_to request.referrer || dashboard_url, alert: message }
          format.json { render json: { errors: [message] }, status: :unprocessable_entity }
        end
      else
        format.html{ redirect_to request.referrer || dashboard_url, alert: I18n.t("controller.leads.alert.sales_user_not_found") }
      end
    end
  end

  def accept_lead
    respond_to do |format|
      if @lead.update(accepted_by_sales: params[:accepted_by_sales])
        @lead.reassign_log_status(nil, params[:event])
        if @lead.accepted_by_sales
          message = I18n.t('controller.leads.accepted_by_sales', status: "Accepted")
        else
          message = I18n.t('controller.leads.accepted_by_sales', status: "Rejected")
        end
        format.html{ redirect_to request.referrer || dashboard_url, notice: message }
        format.json { render json: { message: message }, status: :ok }
      else
        format.html{ redirect_to request.referrer || dashboard_url, alert: @lead.errors.full_messages.uniq }
        format.json { render json: { errors: @lead.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def move_to_next_state
    # if current site visit status is marked as arrived, then the site visit status is changed to conducted
    if @lead.current_site_visit.present? && @lead.current_site_visit.status == 'arrived'
      current_site_visit = @lead.current_site_visit
      current_site_visit.assign_attributes(conducted_on: Time.current, conducted_by: current_user.role, status: 'conducted')
      current_site_visit.save
    end

    respond_to do |format|
      if @lead.move_to_next_state!(params[:status])
        format.html{ redirect_to request.referrer || dashboard_url, notice: I18n.t("controller.leads.move_to_next_state.#{@lead.status}", name: @lead.name.titleize) }
        format.json { render json: { message: I18n.t("controller.leads.move_to_next_state.#{@lead.status}", name: @lead.name.titleize) }, status: :ok }
      else
        format.html{ redirect_to request.referrer || dashboard_url, alert: @lead.errors.full_messages.uniq }
        format.json { render json: { errors: @lead.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def search_inventory
    @leads = Lead.in(id: params[:leads][:ids]&.reject(&:blank?))
    @project_ids = params.dig(:leads, :tp_project_ids).split(',')
    @project_url = ENV_CONFIG.dig('third_party_inventory', 'base_url')

    respond_to do |format|
      if @leads.present? && @project_ids.present?
        email_template = ::Template::EmailTemplate.where(name: "send_tp_projects_link").first
        if email_template.present?
          @leads.each do |lead|
            if lead.email.present?
              email = Email.create!({
                booking_portal_client_id: current_client.id,
                body: ERB.new(current_client.email_header).result(binding) + ERB.new(email_template.content).result(binding).html_safe + ERB.new(current_client.email_footer).result(binding),
                subject: ERB.new(email_template.subject).result(binding).html_safe,
                to: [lead.email],
                triggered_by_id: lead.id,
                triggered_by_type: lead.class.to_s
              })
              email.sent!
            end
          end
        end
        sms_template = ::Template::SmsTemplate.where(name: "send_tp_projects_link").first
        if sms_template.present?
          @leads.each do |lead|
            if lead.phone.present?
              sms_body = ERB.new(sms_template.content).result(binding).html_safe
              sms = Sms.create!({
                booking_portal_client_id: current_client.id,
                body: sms_body,
                to: [lead.phone],
                triggered_by_id: lead.id,
                triggered_by_type: lead.class.to_s
              }) unless sms_body.blank?
            end
          end
        end

        format.json { render json: { message: I18n.t("controller.leads.message.mail_sent") }, status: :ok }
      else
        errors = []
        errors << I18n.t("controller.leads.errors.select_leads") unless @leads.present?
        errors << I18n.t("controller.projects.errors.select_projects") unless @project_ids.present?
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_lead
    @lead = if params[:crm_client_id].present? && params[:id].present?
              find_lead_with_reference_id(params[:crm_client_id], params[:id])
            elsif params[:id].present?
              Lead.where(id: params[:id]).first
            end
    redirect_to root_path, alert: t('controller.users.set_user_missing') if @lead.blank?
  end

  def find_lead_with_reference_id crm_id, reference_id
    _crm = Crm::Base.where(id: crm_id).first
    Lead.where("third_party_references.crm_id": _crm.try(:id), "third_party_references.reference_id": reference_id ).first
  end

  def set_sales_user
    @sales = User.where(id: params[:sales_id], role: 'sales').first
    unless @sales
      flash.now[:alert] = 'Sales user not found'
      render 'assign_sales'
    end
  end

  def authorize_resource
    if %w[new export search_by search_inventory new_kylas_associated_lead create_kylas_associated_lead deal_associated_contact_details new_kylas_lead create_kylas_lead].include?(params[:action])
      authorize [current_user_role_group, Lead]
    elsif params[:action] == 'index'
      unless params[:ds]
        authorize [current_user_role_group, Lead]
      else
        policy([current_user_role_group, Lead]).ds_index?
      end
    else
      authorize [current_user_role_group, @lead]
    end
  end

  def apply_policy_scope
    custom_scope = Lead.where(Lead.user_based_scope(current_user, params))
    Lead.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
