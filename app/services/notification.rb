module Notification
  module Sms
    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["project_id", "booking_portal_client_id", "template_name", "recipient_id", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"
      ::Sms.create!(params.merge(sms_template_id: Template::SmsTemplate.where(project_id: params['project_id'], name: template_name, booking_portal_client_id: params['booking_portal_client_id']).first.try(:id)))
    end
  end

  module Email

    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["project_id", "booking_portal_client_id", "template_name", "recipient_ids", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"
      params.delete("triggered_by_id") if params['triggered_by']
      receipt = params[:triggered_by] || ::Receipt.where(id: params[:triggered_by_id]).first

      email = ::Email.new(params.merge(email_template_id: Template::EmailTemplate.where(name: template_name, project_id: params['project_id'], booking_portal_client_id: params['booking_portal_client_id']).first.try(:id)))
      email.set_content

      if !Rails.env.test? && (%w[clearance_pending success].include?(receipt.status) || ( receipt.online? && !receipt.clearance_pending? ) )
        client = receipt.user.booking_portal_client
        _html = email.body
        pdf_html = ApplicationController.new.render_to_string(inline: _html, layout: 'pdf')

        pdf = WickedPdf.new.pdf_from_string(pdf_html)
        File.open("#{Rails.root}/tmp/receipt_details_#{receipt.receipt_id}.pdf", "wb") do |file|
          file << pdf
        end
        email.attachments.build({file: File.open("#{Rails.root}/tmp/receipt_details_#{receipt.receipt_id}.pdf")})
      end

      email.sent! if email.save
    end
  end
end
