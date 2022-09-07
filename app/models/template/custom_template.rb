class Template::CustomTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  SUBJECT_CLASSES = ["User", "ChannelPartner", "Scheme", "BookingDetail", "Receipt", "BookingDetailScheme", "Lead", "UserKyc", "Invoice"].freeze

  field :name, type: String
  field :subject_class, type: String

  validates :name, :content, :subject_class, presence: true

  belongs_to :booking_portal_client, class_name: 'Client'

  validates :subject_class, inclusion: { in: proc { Template::CustomTemplate::SUBJECT_CLASSES } }, allow_blank: true

end