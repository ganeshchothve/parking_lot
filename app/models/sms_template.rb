class SmsTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :content, type: String

  validates :name, :content, presence: true

  def parsed_content object
    TemplateParser.parse(self.content, object)
  end
end

=begin
SmsTemplate.create({name: "otp", content: "Your OTP for login is {{otp_code}}."})

SmsTemplate.create(name: "cancellation_request_created", content: "We’re sorry to see you go! Your request for cancellation of booking for {{project_unit.name}} has been received. Our CRM team will get in touch with you shortly.")

SmsTemplate.create(name: "receipt_success", content: "Dear {{user.name}}, your payment of Rs. {{total_amount}} was successful ({{receipt_id}}). To print your receipt visit {{user.dashboard_url}}")

SmsTemplate.create(name: "receipt_failed", content: "Dear {{user.name}}, your payment of Rs. {{total_amount}} has failed ({{receipt_id}}).")

SmsTemplate.create(name: "receipt_pending", content: "Dear {{user.name}}, your payment of Rs. {{total_amount}} has been collected and will be sent to the {{user.name}} Team for clearance.")

SmsTemplate.create(name: "receipt_clearance_pending", content: "Dear {{user.name}}, your payment of Rs. {{total_amount}} is under 'Pending Clearance' ({{receipt_id}}). To print your receipt visit {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_6", content: "Only 6 days to go! 6 days to being part of {{booking_portal_client.name}} - the 288 acre iconic township designed for happiness. Click here to pay the pending amount of Rs. {{pending_balance}} for unit {{name}} and secure your home at {{project_name}}: {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_5", content: "A home, an identity - come home to yours. Only 5 days to go before you miss your home at {{project_name}}! Get it before you regret it. Click here to complete paying the pending amount: {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_4", content: "You buy electronics online, you buy groceries online - why not a home? Complete your pending amount of Rs. {{pending_balance}} for unit {{name}} at {{project_name}} on the portal, before you miss your home. You’ve got only 4 days to go! Click to pay: {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_3", content: "A lot can happen in 3 days - today, you have a home at the prestigious {{booking_portal_client.name}} reserved in your name. 3 days from now, you could’ve missed that opportunity. Click here to pay the pending amount of Rs. {{pending_balance}} for unit {{name}} today: {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_2", content: "2 days to go! 2 days until you’ve missed your home at {{project_name}} - or, you could be the proud resident of {{booking_portal_client.name}} today. Click here to complete the transaction of Rs. {{pending_balance}} for unit {{name}}: {{user.dashboard_url}}")

SmsTemplate.create(name: "promote_future_payment_1", content: "Today’s your last chance to call {{name}} at {{project_name}} your home! Complete the payment today, or the apartment will get auto-released for other users to book it. Click here to complete your payment of Rs. {{pending_balance}}: {{user.dashboard_url}}")
=end
