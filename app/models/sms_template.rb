class SmsTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :subject_class, type: String
  field :name, type: String
  field :content, type: String

  validates :name, :content, presence: true

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :sms_templates

  def parsed_content object
    TemplateParser.parse(self.content, object)
  end

  def self.build_criteria params={}
    selector = {}
    self.where(selector)
  end
end
