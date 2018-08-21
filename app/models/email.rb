class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  field :to, type: Array
  field :cc, type: Array
  field :subject, type: String
  field :body, type: String
  field :text_only_body, type: String
  field :email_template_id, type: BSON::ObjectId
  field :status, type: String, default: "draft"
  field :remote_id, type: String
  field :sent_on, type: DateTime
  field :email_thread_id, type: BSON::ObjectId #set only when there's an email conversation. maintains the id of previous email in the thread
  field :cc, type: Array

  validates :subject, presence: true, if: Proc.new{ |model| model.email_template_id.blank? }
  validate :body_or_text_only_body_present?
  validates_inclusion_of :status, in: Proc.new {  self.allowed_statuses.collect{ |hash| hash[:id] } }

  enable_audit reference_ids_without_associations: [{name_of_key: 'email_template_id', method: 'email_template', klass: 'Template::EmailTemplate'}]

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :emails
  has_and_belongs_to_many :recipients, class_name: "User", inverse_of: :received_emails
  has_and_belongs_to_many :cc_recipients, class_name: "User", inverse_of: :cced_emails
  belongs_to :triggered_by, polymorphic: true


  # returns array having statuses, which are allowed on models
  # allowed statuses are used in select2 for populating data on UI side. they also help in validations
  #
  # @return [Array] of hashes
  def self.allowed_statuses
    [
      {id: "draft",text: "Draft", default: true},
      {id: "scheduled", text: "Scheduled"},
      {id: "queued", text: "Queued"},
      {id: "sent", text: "Sent"},
      {id: "delivered", text: "Delivered"},
      {id: "read", text: "Read"},
      {id: "unread", text: "Unread"},
      {id: "clicked", text: "Clicked"},
      {id: "bounced", text: "Bounced"},
      {id: "dropped", text: "Dropped"},
      {id: "spam", text: "Spam"},
      {id: "complained", text: "Complained"},
      {id: "unsubscribed",text: "Unsubscribed"},
      {id: "untracked",text: "Untracked"}
    ]
  end

  # returns the boolean status of email entity, whether it is in draft / untracked stage
  #
  # @return [Boolean]
  def not_draft_or_untracked
    status != "draft" || status != "untracked"
  end

  # returns the subject if email entity
  #
  # @return [String]
  def name
    self.subject
  end

  def attachments
    self.agency.docs.in(id: self.attachment_ids)
  end

  def email_template
    Template::EmailTemplate.where(id: self.email_template_id).first
  end

  private
  # for email template we require body or text. Otherwisse we won't have any content to send to the sender / reciever
  # throws error if the both are blank
  #
  def body_or_text_only_body_present?
    if self.email_template_id.blank?
      if self.body.blank? && self.text_only_body.blank?
        self.errors.add(:base,"Either html-body or text only content is required.")
      end
    end
  end

end
