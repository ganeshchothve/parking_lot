class Sms
  include Mongoid::Document
  include Mongoid::Timestamps

  # Scopes
  scope :filter_by_to, ->(phone) { where(to: phone) }
  scope :filter_by_body, ->(body) { where(body: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, ->(date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, ->(status) { where(status: status) }

  # Fields
  field :to, type: Array
  field :body, type: String
  field :sms_template_id, type: BSON::ObjectId
  field :sent_on, type: DateTime
  field :status, type: String, default: "scheduled"

  # Associations
  belongs_to :recipient, class_name: "User", inverse_of: :received_smses, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :booking_portal_client, class_name: "Client"

  validates :body, presence: true, if: Proc.new{ |model| model.sms_template_id.blank? }
  validates :triggered_by_id, :recipient_id, presence: true
  validates_inclusion_of :status, in: Proc.new { |_model| self.allowed_statuses.collect{ |hash| hash[:id] } }

  enable_audit audit_fields: [:body, :sent_on], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::SmsTemplate"}]

  default_scope -> {desc(:created_at)}

  # Methods

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

  # to apply all filters, to add new filter only add scope in respective model and filter on frontend, new filter parameter must be inside fltrs hash
  def self.build_criteria params={}
    filters = self.all
    if params[:fltrs]
      params[:fltrs].each do |key, value|
        if self.respond_to?("filter_by_#{key}") && value.present?
          filters = filters.send("filter_by_#{key}", *value)
        end
      end
    end
    filters
  end

  # returns an instance of sms_template associated to to entity
  #
  def sms_template
    Template::SmsTemplate.where(id: self.sms_template_id).first
  end
end
