class BookingDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include BookingDetailStateMachine
  include SyncDetails
  include ApplicationHelper
  extend FilterByCriteria
  include PriceCalculator

  BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed]

  field :status, type: String
  field :erp_id, type: String, default: ''
  field :name, type: String
  field :base_rate, type: Float
  field :floor_rise, type: Float
  field :saleable, type: Float
  mount_uploader :tds_doc, DocUploader

  enable_audit(
    indexed_fields: %i[manager_id project_unit_id],
    audit_fields: %i[manager_id status manager_id project_unit_id user_id user_kyc_ids],
    reference_ids_without_associations: [
      { field: 'manager_id', klass: 'ChannelPartner' },
      { field: 'primary_user_kyc_id', klass: 'UserKyc' }
    ]
  )

  embeds_many :costs, as: :costable
  embeds_many :data, as: :data_attributable
  belongs_to :project_unit
  belongs_to :user
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :search, optional: true
  # When a new booking detail object is created from another object, this field will be set. This happens when the user creates a swap request.
  belongs_to :parent_booking_detail, class_name: 'BookingDetail', optional: true
  belongs_to :primary_user_kyc, class_name: 'UserKyc'
  has_many :receipts, dependent: :nullify
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :booking_detail_schemes, dependent: :destroy
  has_many :notes, as: :notable
  has_many :user_requests, as: :requestable
  has_many :related_booking_details, foreign_key: :parent_booking_detail_id, primary_key: :_id, class_name: 'BookingDetail'
  has_and_belongs_to_many :user_kycs

  # TODO: uncomment
  # validates :name, presence: true
  validates :status, :primary_user_kyc_id, presence: true
  validates :erp_id, uniqueness: true, allow_blank: true
  delegate :name, :blocking_amount, to: :project_unit, prefix: true, allow_nil: true
  delegate :name, :email, :phone, to: :user, prefix: true, allow_nil: true
  delegate :name, :email, :phone, :role, :role?, to: :manager, prefix: true, allow_nil: true


  scope :filter_by_name, ->(name) { where(name: ::Regexp.new(::Regexp.escape(name), 'i')) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_tower, ->(project_tower_id) { where(project_unit_id: { "$in": ProjectUnit.where(project_tower_id: project_tower_id).pluck(:_id) })}
  scope :filter_by_user, ->(user_id) { where(user_id: user_id)  }
  scope :filter_by_manager, ->(manager_id) {where(manager_id: manager_id) }
  default_scope -> {desc(:created_at)}


  accepts_nested_attributes_for :notes

  default_scope -> { desc(:created_at) }

  def send_notification!
    message = "#{primary_user_kyc.name} just booked apartment #{project_unit.name} in #{project_unit.project_tower_name}"
    Gamification::PushNotification.new.push(message) if Rails.env.staging? || Rails.env.production?
  end

  def booking_detail_scheme=(bds)
    @booking_detail_scheme = bds
  end

  def booking_detail_scheme
    @booking_detail_scheme ||= booking_detail_schemes.in(status: ['approved', 'draft']).first
  end

  def sync(erp_model, sync_log)
    Api::BookingDetailsSync.new(erp_model, self, sync_log).execute
  end

  #
  # Unit Auto Release is set on when unit moved form hold stage. This Auto release set as Todays date plus client blocking allows date. That time inform client about auto relase date.
  #
  #
  # @return [Email Object]
  #
  def auto_released_extended_inform_buyer!
    email = Email.create!({
      booking_portal_client_id: project_unit.booking_portal_client_id,
      email_template_id: Template::EmailTemplate.find_by(name: "auto_release_on_extended").id,
      cc: [ project_unit.booking_portal_client.notification_email ],
      recipients: [ user ],
      cc_recipients: ( user.manager_id.present? ? [user.manager] : [] ),
      triggered_by_id: self.id,
      triggered_by_type: self.class.to_s
    })
    email.sent!
  end

  def ageing
    _receipts = self.receipts.in(status:["clearance_pending", "success"]).asc(:created_at)
    if(["booked_confirmed"].include?(self.status))
      due_since = _receipts.first.created_at.to_date rescue self.created_at.to_date
      last_booking_payment = _receipts.last.created_at.to_date rescue Date.today
      age = (last_booking_payment - due_since).to_i
    elsif(["blocked", "booked_tentative"].include?(self.status))
      due_since = _receipts.first.created_at.to_date rescue self.created_at.to_date
      age = (Date.today - due_since).to_i
    else
      return "NA"
    end
    if age < 15
      return "< 15 days"
    elsif age < 30
      return "< 30 days"
    elsif age < 45
      return "< 45 days"
    elsif age < 60
      return "< 60 days"
    else
      return "> 60 days"
    end
  end

  def cost_sheet_template(booking_detail_scheme_id = nil)
    booking_detail_scheme_id.present? ? BookingDetailScheme.find(booking_detail_scheme_id).cost_sheet_template : booking_detail_scheme.cost_sheet_template
  end

  def payment_schedule_template(booking_detail_scheme_id = nil)
    booking_detail_scheme_id.present? ? BookingDetailScheme.find(booking_detail_scheme_id).payment_schedule_template : booking_detail_scheme.payment_schedule_template
  end

  def pending_balance(options={})
    strict = options[:strict] || false
    user_id = options[:user_id] || self.user_id
    if user_id.present?
      receipts_total = Receipt.where(user_id: user_id, booking_detail_id: self.id)
      if strict
        receipts_total = receipts_total.where(status: "success")
      else
        receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
      end
      receipts_total = receipts_total.sum(:total_amount)
      return (self.project_unit.booking_price - receipts_total)
    else
      return self.project_unit.booking_price
    end
  end

  def total_tentative_amount_paid
    receipts.where(user_id: self.user_id).in(status: ['success', 'clearance_pending']).sum(:total_amount)
  end

  def total_amount_paid
    receipts.success.sum(:total_amount)
  end

  class << self

    def user_based_scope(user, params = {})

      custom_scope = {}
      if params[:user_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { user_id: { '$in': User.where(role: 'user', manager_id: user.id).distinct(:id) } }
        elsif user.role?('cp_admin')
          custom_scope = { user_id: { "$in": User.where(role: 'user').nin(manager_id: [nil, '']).distinct(:id) } }
        elsif user.role?('cp')
          channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          custom_scope = { user_id: { "$in": User.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
        end
      end

      custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
      custom_scope = { user_id: user.id } if user.buyer?
      custom_scope
    end
  end
end
