module ReceiptsConcern
  extend ActiveSupport::Concern

  # GET /buyer/receipts/export
  # GET /admin/receipts/export
  def export
    if Rails.env.development?
      ReceiptExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      ReceiptExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_receipts_path(fltrs: params[:fltrs].as_json)
  end

  # GET /buyer/receipts/:receipt_id/resend_success
  # GET /admin/receipts/:receipt_id/resend_success
  def resend_success
    user = @receipt.user
    if user.booking_portal_client.email_enabled?
      Email.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(name: 'receipt_success').id,
        recipients: [@receipt.user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      )
    end
    redirect_to (request.referrer.present? ? request.referrer : dashboard_path)
  end

  def selected_account(project_unit = nil)
    if project_unit.nil?
      Account::RazorpayPayment.find_by(by_default: true)
    else
      if project_unit.receipts.count == 0
         Account::RazorpayPayment.find_by(by_default: true)
      else
        project_unit.phase.account
      end
    end
  end
end
