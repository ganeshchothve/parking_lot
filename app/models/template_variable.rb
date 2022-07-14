class TemplateVariable
  include Mongoid::Document
  include Mongoid::Timestamps

  field :number, type: Integer
  field :content, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :sms_template, class_name: "Template::SmsTemplate"

  validates :content, presence: true

  def value object
    if object.present?
      begin
        return ERB.new(self.content).result( object.get_binding ).to_s
      rescue
        return ""
      end
    else
      ""
    end
  end
end
