class Email
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  STATUS = %w(draft scheduled queued sent delivered read unread clicked bounced dropped spam complained unsubscribed untracked)

  # Scopes
  scope :filter_by_to, ->(email) { where(to: email) }
  scope :filter_by_cc, ->(email) { where(cc: email) }
  scope :filter_by_sent_on, ->(date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_subject, ->(subject) { where(subject: ::Regexp.new(::Regexp.escape(subject), 'i')) }
  scope :filter_by_body, ->(body) { where(body: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_status, ->(status) { where(status: status) }

  # Fields
  field :to, type: Array
  field :cc, type: Array
  field :subject, type: String
  field :body, type: String
  field :text_only_body, type: String
  field :status, type: String, default: "draft"
  field :remote_id, type: String
  field :sent_on, type: DateTime
  field :email_thread_id, type: BSON::ObjectId #set only when there's an email conversation. maintains the id of previous email in the thread

  # Validations
  validates :subject, presence: true, if: Proc.new{ |model| model.email_template_id.blank? }
  validates :recipient_ids, :triggered_by_id, presence: true
  validate :body_or_text_only_body_present?
  validates_inclusion_of :status, in: STATUS

  enable_audit reference_ids_without_associations: [{name_of_key: 'email_template_id', method: 'email_template', klass: 'Template::EmailTemplate'}]

  # Associations
  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :emails
  belongs_to :project, optional: true
  belongs_to :email_template, class_name: 'Template::EmailTemplate', optional: true
  has_and_belongs_to_many :recipients, class_name: "User", inverse_of: :received_emails, validate: false
  has_and_belongs_to_many :cc_recipients, class_name: "User", validate: false, inverse_of: :cced_emails
  belongs_to :triggered_by, polymorphic: true, optional: true
  has_many :attachments, as: :assetable, class_name: "Asset"
  accepts_nested_attributes_for :attachments

  index(created_at: 1)

  default_scope -> {desc(:created_at)}

  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }

  # Methods

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

  def sent!
    # Email sent when
    # Template Present  |   Templat Is Active  |   ENV in list  |   SMS sent or not
    #      T            |          T           |       T        |        yes
    #      T            |          T           |       F        |         no
    #      T            |          F           |       T        |         no
    #      T            |          F           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    #      F            |          -           |       T        |        yes
    #      F            |          -           |       F        |         no
    # and alwas send email when email template is missing.
    if self.booking_portal_client.email_enabled? && self.to.present?
      if self.email_template
        Communication::Email::MailgunWorker.perform_async(self.id.to_s) if self.email_template.try(:is_active?)
      else
        Communication::Email::MailgunWorker.perform_async(self.id.to_s)
      end
    end
  end

  def set_content
    if self.body.blank?
      email_template = Template::EmailTemplate.find self.email_template_id
      current_client = self.booking_portal_client
      current_project = self.project
      begin
        self.body = ERB.new((current_project || current_client).email_header).result( binding ) + email_template.parsed_content(triggered_by) + ERB.new((current_project || current_client).email_footer).result( binding )
      rescue => e
        self.body = ""
      end
      self.text_only_body = TemplateParser.parse(email_template.text_only_body, triggered_by)
      self.subject = email_template.parsed_subject(triggered_by)
    else
      self.body = TemplateParser.parse(self.body, triggered_by)
      self.text_only_body = TemplateParser.parse(self.text_only_body, triggered_by)
      self.subject = TemplateParser.parse(self.subject, triggered_by)
    end
  end

  def self.monthly_count(range = nil)
    if range.present?
      from, to = range.split(' - ')
      match_params = {sent_on: {"$gte": Time.parse(from), "$lte": Time.parse(to)}}
    else
      match_params = {sent_on: {"$ne": nil}}
    end

    data = Email.collection.aggregate([
      {
        "$match": match_params
      },{
        "$project":
        {
          month: { "$month": "$sent_on"},
          year: {"$year": "$sent_on"},
          body: "$body"
        }
      },{
        "$group":
        {
          "_id": {year: "$year", month: "$month"},
          count: { "$sum": 1 }
        }
      },{
        "$sort":
        {
          "_id.year": -1,
          "_id.month": -1,
        }
      }
    ]).to_a

    out = data.inject({}) do |hsh, d|
      _key = "#{d.dig('_id', 'month')}/#{d.dig('_id', 'year')}"
      hsh[_key] = d['count']
      hsh
    end
    out['Total'] = out.values.inject(:+)
    out.present? ? out : "No Email data present."
  end

  private

  # for email template we require body or text. Otherwise we won't have any content to send to the sender / reciever
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
