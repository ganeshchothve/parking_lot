class Sms
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  STATUS = %w(received untracked scheduled sent failed)

  # Scopes
  scope :filter_by_to, ->(phone) { where(to: phone) }
  scope :filter_by_body, ->(body) { where(body: ::Regexp.new(::Regexp.escape(body), 'i')) }
  scope :filter_by_sent_on, ->(date) { start_date, end_date = date.split(' - '); where(sent_on: start_date..end_date) }
  scope :filter_by_status, ->(status) { where(status: status) }

  # Fields
  field :to, type: Array
  field :body, type: String
  field :sent_on, type: DateTime
  field :status, type: String, default: "scheduled"

  belongs_to :sms_template, class_name: 'Template::SmsTemplate', optional: true

  # Associations
  belongs_to :recipient, class_name: "User", inverse_of: :received_smses, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :booking_portal_client, class_name: "Client"

  validates :body, presence: true, if: Proc.new{ |model| model.sms_template_id.blank? }
  validates :triggered_by_id, :recipient_id, presence: true
  validates_inclusion_of :status, in: STATUS

  enable_audit audit_fields: [:body, :sent_on], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::SmsTemplate"}]

  default_scope -> {desc(:created_at)}

  def self.sms_pulse(range = nil)
    if range.present?
      from, to = range.split(' - ')
      match_params = {sent_on: {"$gte": Time.parse(from), "$lte": Time.parse(to)}}
    else
      match_params = {sent_on: {"$ne": nil}}
    end
    match_params[:status] = 'sent'

    data = Sms.collection.aggregate([
      {
        "$match": match_params
      },{
        "$unwind": { path: "$to"}
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
          count: { "$sum": {"$ceil": {"$divide": [{ "$strLenCP": "$body" }, 160] }}}
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
    out.present? ? out : "No SMS data present."
  end

end
