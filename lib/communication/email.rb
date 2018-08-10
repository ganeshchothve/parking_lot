module Communication
  module Email
    module Mailgun

      # finds the email object, and email_settings from agency, finds the correct provider and sends the email's json to provider_object for sending the email
      def self.execute email_id
        email = ::Email.find email_id
        email_json = email.as_json.with_indifferent_access
        # if email.attachment_ids.present?
        #   email_json[:attachments] = email.attachments.collect do |doc|
        #     if Rails.env.production? || Rails.env.staging?
        #       CarrierWave::Uploader::Download::RemoteFile.new(doc.file.url)
        #     else
        #       File.open("#{Rails.root}/public" + doc.file.url,'r')
        #     end
        #   end
        # end

        # unless setting[:provider]
        #   fail "An Email Setting json must contain 'provider' key"
        # end
        # setting[:domain] = ::Email.default_email_domain

        begin
          message = get_message_object(email_json)
          mailgun = ::Mailgun::Client.new setting[:private_api_key]
          mailgun.send_message(::Email.default_email_domain, message)
          email.set({sent_on: Time.now})
        rescue StandardError => e
          if Rails.env.production? || Rails.env.staging?
            Honeybadger.notify(e)
          else
            puts "==============================="
            puts "Error sending email:#{e.class} : #{e.message}"
            puts e.backtrace
            puts "==============================="
          end
        end
      end

      def self.get_message_object email_json
        email_json = email_json.with_indifferent_access
        message = ::Mailgun::MessageBuilder.new
        message.add_recipient(:to, email_json[:to])
        message.add_recipient(:cc, email_json[:cc])

        message.from("notifications@sell.do")
        message.subject(email_json[:subject])
        message.body_text(email_json[:text_only_body])
        message.body_html(email_json[:body])

        if(email_json[:tracking].present?)
          message.add_campaign_id(email_json[:tracking][:campaign_id]) if(email_json[:tracking][:campaign_id])
          message.track_clicks(true)
          message.track_opens(true)
        end

        if(email_json[:attachments].present?)
          email_json[:attachments].each do |attachment|
            message.add_attachment(attachment)
          end if email_json[:attachments].is_a?(Array)
          message.add_attachment(email_json[:attachments]) if email_json[:attachments].is_a?(File) || email_json[:attachments].is_a?(String)
        end
        message.message["h:Reply-To"] = email_json[:in_reply_to]
        message.message["v:email_id"] = email_json[:_id].to_s
        message
      end
    end
  end
end
