class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  include InvoiceStateMachine
  extend FilterByCriteria
  include NumberIncrementor

  DOCUMENT_TYPES = []

  field :amount, type: Float, default: 0.0
  field :gst_amount, type: Float, default: 0.0
  field :status, type: String, default: 'draft'
  field :raised_date, type: DateTime
  field :processing_date, type: DateTime
  field :approved_date, type: DateTime
  field :rejection_reason, type: String
  field :comments, type: String
  field :net_amount, type: Float

  belongs_to :project
  belongs_to :booking_detail
  belongs_to :manager, class_name: 'User'
  has_one :incentive_deduction
  has_many :assets, as: :assetable
  embeds_one :cheque_detail
  embeds_one :payment_adjustment, as: :payable

  validates :number, presence: true, if: :raised?
  validates :rejection_reason, presence: true, if: :rejected?
  validates :comments, presence: true, if: proc { pending_approval? && status_was == 'rejected' }
  validates :amount, numericality: { greater_than: 0 }
  validates :cheque_detail, presence: true, if: :paid?
  validates :cheque_detail, copy_errors_from_child: true, if: :cheque_detail?
  validates :net_amount, numericality: { greater_than: 0 }, if: :approved?

  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :name, to: :manager, prefix: true, allow_nil: true

  scope :filter_by_invoice_type, ->(request_type){ where(_type: /#{request_type}/i)}
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_booking_detail_id, ->(booking_detail_id) { where(booking_detail_id: booking_detail_id) }
  scope :filter_by_channel_partner_id, ->(channel_partner_id) { where(manager_id: channel_partner_id) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }

  accepts_nested_attributes_for :cheque_detail, reject_if: proc { |attrs| attrs.except('creator_id').values.all?(&:blank?) }
  accepts_nested_attributes_for :payment_adjustment, reject_if: proc { |attrs| attrs['absolute_value'].blank? }

  def calculated?
    _type.match(/calculated/i)
  end

  def manual?
    _type.match(/manual/i)
  end

  class << self
    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:booking_detail_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { manager_id: user.id }
        elsif user.role?('billing_team')
          custom_scope = { status: { '$nin': %w(draft) } }
        elsif user.role?('cp_admin')
          #cp_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
          #channel_partner_ids = User.where(role: 'channel_partner', manager_id: {"$in": cp_ids}).distinct(:id)
          #custom_scope = { manager_id: { "$in": channel_partner_ids }, status: { '$nin': %w(draft) } }
          custom_scope = { status: { '$nin': %w(draft raised) } }
        #elsif user.role?('cp')
        #  channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
        #  custom_scope = { manager_id: { "$in": channel_partner_ids } }
        end
      end
      if params[:booking_detail_id].present?
        custom_scope = { booking_detail_id: params[:booking_detail_id] }
      end
      custom_scope = { booking_detail_id: { '$in': user.booking_details.distinct(:id) } } if user.buyer?
      if user.project_ids.present?
        project_ids = user.project_ids.map{|project_id| BSON::ObjectId(project_id) }
        custom_scope.merge!({project_id: {"$in": project_ids}})
      end
      custom_scope
    end

    def user_based_available_statuses(user)
      if user.present?
        if user.role?('billing_team')
          %w[raised pending_approval approved rejected]
        elsif user.role?('cp_admin')
          Invoice.aasm.states.map(&:name) - [:draft, :raised]
        else
          Invoice.aasm.states.map(&:name)
        end
      else
        Invoice.aasm.states.map(&:name)
      end
    end
  end
end
