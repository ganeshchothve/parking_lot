class Lead
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include CrmIntegration
  include LeadNotifications
  include InsertionStringMethods
  extend FilterByCriteria
  extend ApplicationHelper

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)

  field :first_name, type: String, default: ''
  field :last_name, type: String, default: ''
  field :email, type: String, default: ''
  field :phone, type: String, default: ''
  field :stage, type: String
  field :sitevisit_date, type: Date
  field :revisit_count, type: Integer
  field :last_revisit_date, type: Date
  field :registered_at, type: Date
  field :manager_change_reason, type: String
  field :referenced_manager_ids, type: Array, default: []
  field :iris_confirmation, type: Boolean, default: false

  belongs_to :user
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :project
  has_many :receipts
  has_many :searches
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :assets, as: :assetable
  has_many :notes, as: :notable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :whatsapps, as: :triggered_by, class_name: 'Whatsapp'
  has_many :project_units
  #has_and_belongs_to_many :received_emails, class_name: 'Email', inverse_of: :recipients
  #has_and_belongs_to_many :cced_emails, class_name: 'Email', inverse_of: :cc_recipients
  #has_many :received_smses, class_name: 'Sms', inverse_of: :recipient
  #has_many :received_whatsapps, class_name: 'Whatsapp', inverse_of: :recipient

  validates_uniqueness_of :user, scope: [:stage, :project_id], message: 'already exists with same stage'
  validates :first_name, presence: true
  validates :first_name, :last_name, name: true, allow_blank: true
  # validate :phone_or_email_required, if: proc { |user| user.phone.blank? && user.email.blank? }
  # validates :phone, :email, uniqueness: { allow_blank: true }
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP } , allow_blank: true

  # delegate :first_name, :last_name, :name, :email, :phone, to: :user, prefix: false, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :name, :role, :role?, :email, to: :manager, prefix: true, allow_nil: true
  delegate :role, :role?, to: :user, prefix: true, allow_nil: true

  def phone_or_email_required
    errors.add(:base, 'Email or Phone is required')
  end

  scope :filter_by__id, ->(_id) { where(_id: _id) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :filter_by_manager_id, ->(manager_id) {where(manager_id: manager_id) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where({ '$and' => ["$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] ] }) }

  scope :filter_by_receipts, ->(receipts) do
    lead_ids = Receipt.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).distinct(:lead_id)
    if lead_ids.present?
      if receipts == 'yes'
        where(id: { '$in': lead_ids })
      elsif receipts == 'no'
        where(id: { '$nin': lead_ids })
      end
    end
  end

  def unattached_blocking_receipt(blocking_amount = nil)
    blocking_amount ||= current_client.blocking_amount
    Receipt.where(lead_id: id).in(status: %w[success clearance_pending]).where(booking_detail_id: nil).where(total_amount: { "$gte": blocking_amount }).asc(:token_number).first
  end

  def is_payment_done?
    receipts.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).present?
  end

  def total_amount_paid
    receipts.where(status: 'success').sum(:total_amount)
  end

  def total_balance_pending
    booking_details.in(status: ProjectUnit.booking_stages).sum(&:pending_balance)
  end

  def total_unattached_balance
    receipts.in(status: %w[success clearance_pending]).where(booking_detail_id: nil).sum(:total_amount)
  end

  def get_search(project_unit_id)
    search = searches
    search = search.where(project_unit_id: project_unit_id) if project_unit_id.present?
    search = search.desc(:created_at).first
    search = Search.create(lead: self) if search.blank?
    search
  end

  def name
    "#{first_name} #{last_name}"
  end

  def ds_name
    "#{name} (#{project_name})"
  end

  class << self

    def user_based_scope(user, params = {})
      custom_scope = {}
      case user.role.to_sym
      when :channel_partner
        custom_scope[:'$or'] = [{manager_id: user.id}, {manager_id: nil, referenced_manager_ids: user.id, iris_confirmation: false}]
      when :cp
        custom_scope = { manager_id: { "$in": User.where(role: 'channel_partner', manager_id: user.id).distinct(:id) } }
      when :cp_admin
        cp_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
        custom_scope = { manager_id: { "$in": User.where(role: 'channel_partner').in(manager_id: cp_ids).distinct(:id) }  }
      end
      custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
      custom_scope = { user_id: user.id } if user.buyer?
      custom_scope
    end

  end
end
