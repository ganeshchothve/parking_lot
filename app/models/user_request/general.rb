class UserRequest::General < UserRequest

  DEPARTMENTS = %w( billing sourcing sales )
  PRIORITIES = %w( low medium high )
  
  field :subject, type: String
  field :description, type: String
  field :department, type: String
  field :priority, type: String, default: 'medium'
  field :tags, type: Array, default: []
  field :due_date, type: Date
  field :category, type: String, default: ''

  belongs_to :assignee, class_name: 'User', optional: true
  
  validates :priority, :subject, :description, :category, presence: true
  validates :department, inclusion: {in: proc{ UserRequest::General::DEPARTMENTS } }, allow_blank: true
  validates :priority, inclusion: {in: proc{ UserRequest::General::PRIORITIES } }, allow_blank: true
  validates :category, inclusion: {in: proc{ |record| record.user.booking_portal_client.general_user_request_categories } }

  enable_audit(
    indexed_fields: %i[],
    audit_fields: %i[status]
  )
end
