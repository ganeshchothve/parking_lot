class Admin::LeadsController < AdminController
  before_action :authenticate_user!
  before_action :set_lead, except: %i[index new export]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  def new
    @lead = Lead.new()
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
      LeadExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_leads_path(fltrs: params[:fltrs].as_json)
  end

  def update
    respond_to do |format|
      if @lead.update(permitted_attributes([:admin, @lead]))
        format.html { redirect_to admin_leads_path, notice: 'Lead successfully updated.' }
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

  def sync_site_visit
    @lead.sitevisit_date, @lead.sitevisit_status = FetchLeadData.site_visit_status_and_date(@lead.lead_id, @lead.user.booking_portal_client, @lead.project.selldo_id.to_s)
    @lead.save
    respond_to do |format|
      format.js
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

  def authorize_resource
    if %w[index new export].include?(params[:action])
      authorize [current_user_role_group, Lead]
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
