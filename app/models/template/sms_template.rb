class Template::SmsTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject_class, type: String
  field :content, type: String

  validates :name, :content, :subject_class, presence: true

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :sms_templates
end
