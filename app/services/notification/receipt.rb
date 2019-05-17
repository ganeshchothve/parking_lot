module Notification
  class Receipt
    def initialize id, changes={}
      @receipt = ::Receipt.find id
      @user = @receipt.user
      @client = @user.booking_portal_client
      @changes = changes
    end

    def execute
      if @changes[:status].present?
        if @client.sms_enabled?
          params = self.sms_params
          Notification::Sms.execute(params) if params[:template_name].present?
        end
        if @client.email_enabled?
          params = self.email_params
          Notification::Email.execute(params) if params[:template_name].present?
        end
      end
    end

    def email_params
      params = {
        booking_portal_client_id: @user.booking_portal_client_id,
        recipient_ids: [@user.id],
        cc_recipient_ids: (@user.manager_id.present? ? [@user.manager_id] : []),
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      }

      new_status = @changes[:status][1]

      params[:template_name] = "receipt_#{new_status}"
      # params[:template_name] = if new_status == "success"
      #   "receipt_success"
      # elsif new_status == "failed"
      #   "receipt_failed"
      # elsif new_status == "clearance_pending"
      #   "receipt_clearance_pending"
      # elsif new_status == "pending" && @receipt.payment_mode != 'online'
      #   "receipt_pending_offline"
      # elsif new_status == "refunded"
      #   "receipt_refunded"
      # end
      params
    end

    def sms_params
      params = {
        booking_portal_client_id: @user.booking_portal_client_id,
        recipient_id: @user.id,
        triggered_by_id: @receipt.id,
        triggered_by_type: @receipt.class.to_s
      }

      new_status = @changes[:status][1]

      params[:template_name] = "receipt_#{new_status}"
      # params[:template_name] = if new_status == "success"
      #   "receipt_success"
      # elsif new_status == "failed"
      #   "receipt_failed"
      # elsif new_status == "clearance_pending"
      #   "receipt_clearance_pending"
      # elsif new_status == "pending" && @receipt.payment_mode != 'online'
      #   "receipt_pending"
      # end
      params
    end
  end
end
