class Sms
  include Mongoid::Document
  include Mongoid::Timestamps

  field :to, type: Array
  field :body, type: String
  field :sms_template_id, type: BSON::ObjectId
  field :sent_on, type: DateTime
  field :status, type: String, default: "scheduled"

  belongs_to :recipient, class_name: "User", inverse_of: :received_smses
  belongs_to :triggered_by, polymorphic: true
  belongs_to :booking_portal_client, class_name: "Client"

  validates :body, presence: true, if: Proc.new{ |model| model.sms_template_id.blank? }
  validates_inclusion_of :status, in: Proc.new { |_model| self.allowed_statuses.collect{ |hash| hash[:id] } }

  enable_audit audit_fields: [:body, :sent_on], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::SmsTemplate"}]

  default_scope -> {desc(:created_at)}

  # returns array having statuses, which are allowed on models
  # allowed statuses are used in select2 for populating data on UI side. they also help in validations
  #
  # @return [Array] of hashes
  def self.allowed_statuses
    [
      {id: "received", text: "Received"},
      {id: "untracked", text: "Untracked"},
      {id: "scheduled", text: "Scheduled"},
      {id: "sent", text: "Sent"},
      {id: "failed", text: "Failed"}
    ]
  end

  # returns an instance of sms_template associated to to entity
  #
  def sms_template
    Template::SmsTemplate.where(id: self.sms_template_id).first
  end
end
