#
# Class Whatsapp provides model for whatsapp
# will store information for the whatsapp
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
class Whatsapp
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  # now handled only sent and failed later will add callback
  STATUSES = %w[queued failed sent delivered read]

  field :api_version, type: String
  field :to, type: String
  field :from, type: String
  field :content, type: String
  field :status, type: String, default: 'queued' # queued, failed, sent, delivered, read, received
  field :channel_install_id, type: String # just for more info
  field :message_sid, type: String # for queued, send, delivered, read message
  field :media_url, type: String # png, jpg, jpeg, pdf, mp3, ogg, amr, mp4, map link
  field :vendor, type: String, default: 'WhatsappNotifier::Twilio'
  field :template_id, type: String
  field :in_reply_to, type: String
  field :sent_on, type: DateTime

  scope :filter_by_to, -> (phone) { where(to: phone) }
  scope :filter_by_content, -> (content) { where(content: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, -> (date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, -> (status) { where(status: status) }

  # Associations
  belongs_to :recipient, class_name: 'User', inverse_of: :received_whatsapps, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true, class_name: 'User'
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :whatsapp_template, class_name: 'Template::WhatsappTemplate', optional: true

  # Validations
  validates :content, presence: true, if: Proc.new{ |model| model.whatsapp_template_id.blank? }
  validates :triggered_by_id, :recipient_id, presence: true
  validates_inclusion_of :status, in: STATUSES
  # validate media_size # up to 5 MB in size (incase of pdf and mp4 and mp3)
  validates :to, :from, presence: true, if: -> { self.vendor == 'WhatsappNotifier::Twilio' }

  enable_audit audit_fields: [:content, :created_at], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::WhatsappTemplate"}]

  default_scope -> { desc(:created_at) }

end