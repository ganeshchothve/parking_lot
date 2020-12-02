class Template::SmsTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject_class, type: String
  field :content, type: String
  field :temp_id, type: String
  field :dlt_header_id, type: String
  field :dlt_temp_id, type: String

  validates :name, :content, :subject_class, presence: true

  has_many :template_variables, dependent: :destroy, class_name: "TemplateVariable"
  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :sms_templates

  accepts_nested_attributes_for :template_variables, allow_destroy: true
end
