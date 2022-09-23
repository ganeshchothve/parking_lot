class Template::CustomTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  SUBJECT_CLASSES = ["BookingDetail", "Receipt", "Lead", "Invoice", "UserRequest::Cancellation", "UserRequest::Swap"].freeze

  field :name, type: String
  field :subject_class, type: String

  validates :name, :content, :subject_class, presence: true

  belongs_to :booking_portal_client, class_name: 'Client'
  has_and_belongs_to_many :projects, class_name: 'Project', inverse_of: nil

  scope :filter_by_project_ids, ->(project_ids){ project_ids.is_a?(Array) ? where(project_ids: { '$elemMatch': { '$in': project_ids } }) : where(project_ids: project_ids) }


  validates :subject_class, inclusion: { in: proc { Template::CustomTemplate::SUBJECT_CLASSES } }, allow_blank: true

end