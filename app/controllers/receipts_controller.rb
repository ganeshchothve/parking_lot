class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_receipt, except: :export
  before_action :set_project_unit
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :export

  layout :set_layout

  def export
    if Rails.env.development?
      ReceiptExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      ReceiptExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_receipts_path(fltrs: params[:fltrs].as_json)
  end

  def resend_success
    user = @receipt.user
    if user.booking_portal_client.email_enabled?
      Email.create!({
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id:Template::EmailTemplate.find_by(name: "receipt_success").id,
        recipients: [@receipt.user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      })
    end
    redirect_to (request.referrer.present? ? request.referrer : dashboard_path)
  end

  def show
    @receipt = Receipt.find(params[:id])
    authorize @receipt
  end

  private

  def set_receipt
    @receipt = Receipt.find(params[:id])
  end

  def set_user
    if current_user.buyer?
      @user = current_user
    else
      @user = (params[:user_id].present? ? User.find(params[:user_id]) : nil)
    end
  end

  def set_project_unit
    @project_unit = if params[:project_unit_id].present?
      ProjectUnit.find(params[:project_unit_id])
    elsif params[:receipt].present? && params[:receipt][:project_unit_id].present?
      ProjectUnit.find(params[:receipt][:project_unit_id])
    elsif @receipt.present?
      @receipt.project_unit
    end
  end

  def authorize_resource
    if params[:action] == 'export'
      authorize Receipt
    else
      authorize @receipt
    end
  end

  def apply_policy_scope
    custom_scope = Receipt.where(Receipt.user_based_scope(current_user, params))
    Receipt.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
