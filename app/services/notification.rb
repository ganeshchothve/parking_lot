module Notification
  module Sms
    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["booking_portal_client_id", "template_name", "recipient_id", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"

      ::Sms.create!(params.merge(sms_template_id: Template::SmsTemplate.where(booking_portal_client_id: params[:booking_portal_client_id]).find_by(name: template_name).id))
    end
  end

  module Email
    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["booking_portal_client_id", "template_name", "recipient_ids", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"
      receipt = ::Receipt.find params[:triggered_by_id]
      if %w[clearance_pending success].include?(receipt.status)
        pdf = WickedPdf.new.pdf_from_string(Template::ReceiptTemplate.first.parsed_content(receipt))
        File.open("#{Rails.root}/tmp/receipt_details_#{receipt.receipt_id}.pdf", "wb") do |file|
          file << pdf
        end
        attachments_attributes = []
        attachments_attributes << {file: File.open("#{Rails.root}/tmp/receipt_details_#{receipt.receipt_id}.pdf")}
        params[:attachments_attributes] = attachments_attributes
      end
      ::Email.create!(params.merge(email_template_id: Template::EmailTemplate.where(booking_portal_client_id: params[:booking_portal_client_id]).find_by(name: template_name).id))
    end
  end
end
