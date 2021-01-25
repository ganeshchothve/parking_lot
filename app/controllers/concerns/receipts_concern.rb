module ReceiptsConcern
  extend ActiveSupport::Concern

  # GET /buyer/receipts/export
  # GET /admin/receipts/export
  def export
    authorize([current_user_role_group, Receipt])
    ReceiptExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_receipts_path(fltrs: params[:fltrs].as_json)
  end

  # GET /buyer/receipts/:receipt_id/resend_success
  # GET /admin/receipts/:receipt_id/resend_success
  def resend_success
    authorize([current_user_role_group, @receipt])
    user = @receipt.user
    if user.booking_portal_client.email_enabled?
      email = Email.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(name: 'receipt_success').id,
        recipients: [@receipt.user],
        cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      )
      email.sent!
    end
    flash[:notice] = t('controller.receipts.resend_email.success')
    redirect_to (request.referrer.present? ? request.referrer : dashboard_path)
  end
end
