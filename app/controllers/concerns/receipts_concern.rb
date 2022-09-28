module ReceiptsConcern
  extend ActiveSupport::Concern

  #
  # This index action for Admin users where Admin can view all receipts.
  #
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/receipts
  def index
    authorize([current_user_role_group, Receipt])
    @receipts = Receipt.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @receipts.as_json(methods: [:name]) }
      format.html
    end
  end

  # GET /buyer/receipts/export
  # GET /admin/receipts/export
  def export
    authorize([current_user_role_group, Receipt])
    ReceiptExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    flash[:notice] = I18n.t("global.export_scheduled")
    redirect_to admin_receipts_path(fltrs: params[:fltrs].as_json)
  end

  # GET /buyer/receipts/:receipt_id/resend_success
  # GET /admin/receipts/:receipt_id/resend_success
  def resend_success
    authorize([current_user_role_group, @receipt])
    lead = @receipt.lead
    user = lead.user
    if user.booking_portal_client.email_enabled?
      email = Email.create!(
        project_id: @receipt.project_id,
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(project_id: @receipt.project_id, name: "receipt_#{@receipt.status}").id,
        recipients: [user],
        cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        cc_recipients: (lead.manager_id.present? ? [lead.manager] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      )
      email.sent!
    end
    flash[:notice] = t('controller.receipts.resend_email.success')
    redirect_to (request.referrer.present? ? request.referrer : dashboard_path)
  end

  private

  def apply_policy_scope
    custom_scope = Receipt.all.where(Receipt.user_based_scope(current_user))
    Receipt.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

end
