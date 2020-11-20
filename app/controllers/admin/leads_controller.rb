class Admin::LeadsController < AdminController
  before_action :authenticate_user!
  before_action :set_lead, except: %i[index]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

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
  end

  def edit
    render layout: false
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
    if %w[index].include?(params[:action])
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
