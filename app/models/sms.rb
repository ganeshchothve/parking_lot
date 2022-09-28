class Sms
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  extend FilterByCriteria

  STATUS = %w(received untracked scheduled sent failed)
  SMS_GATEWAYS = %w(knowlarity sms_just twilio)

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
  field :sms_gateway, type: String
  field :variable_list, type: Array

  belongs_to :sms_template, class_name: 'Template::SmsTemplate', optional: true

  # Associations
  belongs_to :recipient, class_name: "User", inverse_of: :received_smses, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :booking_portal_client, class_name: "Client"
  belongs_to :project, optional: true

  validates :body, presence: true, if: Proc.new{ |model| model.sms_template_id.blank? }
  validates :triggered_by_id, presence: true
  validates :recipient_id, presence: true, if: Proc.new { |sms| sms.to.blank? }
  validates :to, presence: true, if: Proc.new { |sms| sms.recipient_id.blank? }
  validates_inclusion_of :status, in: STATUS
  validates_inclusion_of :sms_gateway, in: SMS_GATEWAYS, allow_blank: true

  enable_audit audit_fields: [:body, :sent_on], reference_ids_without_associations: [{field: "sms_template_id", klass: "Template::SmsTemplate"}]

  default_scope -> {desc(:created_at)}
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }

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
          sms_gateway: "$sms_gateway",
          body: "$body"
        }
      },{
        "$group":
        {
          "_id": {sms_gateway: "$sms_gateway", year: "$year", month: "$month"},
          count: { "$sum": {"$ceil": {"$divide": [{ "$strLenCP": "$body" }, 160] }}}
        }
      },{
        "$sort":
        {
          "_id.year": -1,
          "_id.month": -1,
          "_id.sms_gateway": 1
        }
      }
    ]).to_a

    out = data.inject({}) do |hsh, d|
      _key = "#{d.dig('_id', 'month')}/#{d.dig('_id', 'year')}"
      hsh[_key] ||= {}
      hsh[_key][d["_id"]["sms_gateway"]] = d['count'].to_i
      hsh
    end
    SMS_GATEWAYS.each do |gateway|
      out['Total'] ||= {}
      out['Total'][gateway] = out.values.sum { |hsh| hsh[gateway.to_s].to_i }
    end
    out.present? ? out : "No SMS data present."
  end

  class << self

    def user_based_scope user, params = {}
      if user.role?(:superadmin)
        custom_scope = { booking_portal_client: user.selected_client }
      else
        custom_scope = { booking_portal_client: user.booking_portal_client }
      end
      custom_scope
    end

  end

end
